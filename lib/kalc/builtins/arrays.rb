# Array, lookup, and table-oriented builtin functions.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Spreadsheet-style array and lookup functions.
    module Arrays
      module_function

      MISSING = Object.new.freeze

      # Raised when MATCH or XLOOKUP cannot find a requested value.
      class LookupNotFoundError < ArgumentError
      end

      # Registers the array builtin functions.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_eager(env, :ROWS) { |array| array_value(array, :ROWS).row_count }
        Helpers.define_eager(env, :COLUMNS) { |array| array_value(array, :COLUMNS).column_count }
        Helpers.define_eager(env, :INDEX) do |array, row_index, column_index = nil|
          index_value(array, row_index, column_index)
        end
        Helpers.define_eager(env, :MATCH) do |lookup_value, lookup_array, match_type = 0|
          match_index(lookup_value, lookup_array, match_type)
        end
        Helpers.define_eager(env, :XLOOKUP) do |lookup_value, lookup_array, return_array,
                                                 if_not_found = MISSING, match_mode = 0|
          xlookup(lookup_value, lookup_array, return_array, if_not_found, match_mode)
        end
        Helpers.define_eager(env, :TRANSPOSE) { |array| array_value(array, :TRANSPOSE).transpose }
        Helpers.define_eager(env, :UNIQUE) do |array, by_col = false, exactly_once = false|
          unique(array, by_col, exactly_once)
        end
        Helpers.define_eager(env, :SORT) do |array, sort_index = 1, sort_order = 1, by_col = false|
          sort_array(array, sort_index, sort_order, by_col)
        end
        Helpers.define_eager(env, :FILTER) do |array, include, if_empty = MISSING|
          filter_array(array, include, if_empty)
        end
        Helpers.define_eager(env, :SEQUENCE) do |rows, columns = 1, start = 1, step = 1|
          sequence(rows, columns, start, step)
        end
      end

      # Returns a scalar from an array using Excel-style indexing.
      #
      # @param array [Object]
      # @param row_index [Numeric]
      # @param column_index [Numeric, nil]
      # @return [Object]
      def index_value(array, row_index, column_index)
        array_value(array, :INDEX).value_at(Integer(row_index), column_index && Integer(column_index))
      end

      # Returns the one-based position of a lookup value inside a vector.
      #
      # @param lookup_value [Object]
      # @param lookup_array [Object]
      # @param match_type [Numeric]
      # @return [Integer]
      def match_index(lookup_value, lookup_array, match_type)
        values = vector_values(lookup_array, :MATCH)
        match_type = normalize_match_type(match_type)

        find_match_index(values, lookup_value, match_type)
      end

      # Looks up a value in one array and returns the paired entry from another.
      #
      # @param lookup_value [Object]
      # @param lookup_array [Object]
      # @param return_array [Object]
      # @param if_not_found [Object]
      # @param match_mode [Numeric]
      # @return [Object]
      def xlookup(lookup_value, lookup_array, return_array, if_not_found, match_mode)
        lookup = array_value(lookup_array, :XLOOKUP)
        return_values = array_value(return_array, :XLOOKUP)
        match_mode = normalize_xlookup_match_mode(match_mode)
        index = find_xlookup_index(lookup.vector_values, lookup_value, match_mode)

        extract_lookup_result(return_values, lookup, index)
      rescue LookupNotFoundError
        return if_not_found unless if_not_found.equal?(MISSING)

        raise
      end

      # Returns the unique rows, columns, or vector entries from an array.
      #
      # @param array [Object]
      # @param by_col [Boolean]
      # @param exactly_once [Boolean]
      # @return [Ast::ArrayValue]
      def unique(array, by_col, exactly_once)
        input = array_value(array, :UNIQUE)

        if input.vector?
          values = non_empty_unique_entries(input.vector_values, exactly_once)
          return vector_array(values, input)
        end

        if by_col
          columns = (1..input.column_count).map { |index| input.column(index) }
          return Ast::ArrayValue.new(non_empty_unique_entries(columns, exactly_once).transpose)
        end

        Ast::ArrayValue.new(non_empty_unique_entries(input.rows, exactly_once))
      end

      # Ensures UNIQUE does not return an invalid empty array value.
      #
      # @param entries [Array<Object>]
      # @param exactly_once [Boolean]
      # @return [Array<Object>]
      def non_empty_unique_entries(entries, exactly_once)
        values = unique_entries(entries, exactly_once)
        raise ArgumentError, 'UNIQUE returned no results' if values.empty?

        values
      end

      # Sorts an array by row or column keys.
      #
      # @param array [Object]
      # @param sort_index [Numeric]
      # @param sort_order [Numeric]
      # @param by_col [Boolean]
      # @return [Ast::ArrayValue]
      def sort_array(array, sort_index, sort_order, by_col)
        input = array_value(array, :SORT)
        order = normalize_sort_order(sort_order)

        return sort_vector(input, order) if input.vector?
        return sort_columns(input, sort_index, order) if by_col

        sort_rows(input, sort_index, order)
      end

      # Filters an array by a row or column inclusion mask.
      #
      # @param array [Object]
      # @param include [Object]
      # @param if_empty [Object]
      # @return [Object]
      def filter_array(array, include, if_empty)
        input = array_value(array, :FILTER)
        mask = array_value(include, :FILTER)
        filtered = case filter_dimension(input, mask)
                   when :rows
                     filter_rows(input, mask.vector_values)
                   when :columns
                     filter_columns(input, mask.vector_values)
                   end

        return filtered unless filtered.nil?
        return if_empty unless if_empty.equal?(MISSING)

        raise ArgumentError, 'FILTER returned no results'
      end

      # Builds a numeric sequence array.
      #
      # @param rows [Numeric]
      # @param columns [Numeric]
      # @param start [Numeric]
      # @param step [Numeric]
      # @return [Ast::ArrayValue]
      def sequence(rows, columns, start, step)
        row_count = Integer(rows)
        column_count = Integer(columns)
        raise ArgumentError, 'SEQUENCE rows must be positive' if row_count <= 0
        raise ArgumentError, 'SEQUENCE columns must be positive' if column_count <= 0

        current = start
        values = row_count.times.map do
          column_count.times.map do
            value = current
            current += step
            value
          end
        end

        Ast::ArrayValue.new(values)
      end

      # Coerces a value to an array for a named builtin.
      #
      # @param value [Object]
      # @param function_name [String, Symbol]
      # @return [Ast::ArrayValue]
      def array_value(value, function_name)
        Helpers.expect_array!(value, function_name)
      end

      # Returns the values from a one-dimensional array.
      #
      # @param value [Object]
      # @param function_name [String, Symbol]
      # @return [Array<Object>]
      def vector_values(value, function_name)
        array = array_value(value, function_name)
        raise ArgumentError, "#{function_name} expects a 1D array" unless array.vector?

        array.vector_values
      end

      # Resolves a MATCH lookup against a normalized vector.
      #
      # @param values [Array<Object>]
      # @param lookup_value [Object]
      # @param match_type [Integer]
      # @return [Integer]
      def find_match_index(values, lookup_value, match_type)
        index = case match_type
                when 0
                  values.index(lookup_value)
                when 1
                  find_nearest_match(values, lookup_value, :<=, select: :max)
                when -1
                  find_nearest_match(values, lookup_value, :>=, select: :min)
                end

        raise LookupNotFoundError, "MATCH could not find #{lookup_value.inspect}" unless index

        index + 1
      end

      # Resolves the row or column index used by XLOOKUP.
      #
      # @param values [Array<Object>]
      # @param lookup_value [Object]
      # @param match_mode [Integer]
      # @return [Integer]
      def find_xlookup_index(values, lookup_value, match_mode)
        exact_match = values.index(lookup_value)
        return exact_match + 1 if exact_match

        case match_mode
        when 0
          raise LookupNotFoundError, "XLOOKUP could not find #{lookup_value.inspect}"
        when -1
          find_nearest_match(values, lookup_value, :<=, select: :max) + 1
        when 1
          find_nearest_match(values, lookup_value, :>=, select: :min) + 1
        end
      end

      # Finds the nearest comparable value in a lookup vector.
      #
      # @param values [Array<Object>]
      # @param lookup_value [Object]
      # @param operator [Symbol]
      # @param select [Symbol]
      # @return [Integer, nil]
      def find_nearest_match(values, lookup_value, operator, select:)
        candidates = values.each_with_index.filter_map do |value, index|
          next unless comparable?(value, lookup_value) && value.public_send(operator, lookup_value)

          [value, index]
        end

        case select
        when :max
          candidates.max_by { |value, _candidate_index| sort_key(value) }&.last
        when :min
          candidates.min_by { |value, _candidate_index| sort_key(value) }&.last
        end
      end

      # Extracts the lookup result using the matched one-based index.
      #
      # @param return_array [Ast::ArrayValue]
      # @param lookup_array [Ast::ArrayValue]
      # @param index [Integer]
      # @return [Object]
      def extract_lookup_result(return_array, lookup_array, index)
        length = lookup_array.vector_values.length

        if return_array.vector?
          validate_lookup_length!(length, return_array.vector_values.length, :XLOOKUP)
          return return_array.vector_values.fetch(index - 1)
        end

        if lookup_array.column_vector?
          validate_lookup_length!(length, return_array.row_count, :XLOOKUP)
          row = return_array.row(index)
          return row.first if row.length == 1

          return Ast::ArrayValue.row(row)
        end

        validate_lookup_length!(length, return_array.column_count, :XLOOKUP)
        column = return_array.column(index)
        return column.first if column.length == 1

        Ast::ArrayValue.column(column)
      end

      # Ensures that XLOOKUP arrays line up.
      #
      # @param expected [Integer]
      # @param actual [Integer]
      # @param function_name [String, Symbol]
      # @return [void]
      def validate_lookup_length!(expected, actual, function_name)
        return if expected == actual

        raise ArgumentError, "#{function_name} arrays must have the same length"
      end

      # Returns unique entries while preserving order.
      #
      # @param entries [Array<Object>]
      # @param exactly_once [Boolean]
      # @return [Array<Object>]
      def unique_entries(entries, exactly_once)
        counts = entries.tally
        entries.select { |entry| exactly_once ? counts.fetch(entry) == 1 : counts.fetch(entry) >= 1 }.uniq
      end

      # Normalizes the SORT order argument.
      #
      # @param sort_order [Numeric]
      # @return [Integer]
      def normalize_sort_order(sort_order)
        order = Integer(sort_order)
        return order if [1, -1].include?(order)

        raise ArgumentError, 'SORT order must be 1 or -1'
      end

      # Sorts a row or column vector.
      #
      # @param array [Ast::ArrayValue]
      # @param order [Integer]
      # @return [Ast::ArrayValue]
      def sort_vector(array, order)
        values = stable_sort(array.vector_values, order) { |value| value }
        vector_array(values, array)
      end

      # Sorts a table by one column.
      #
      # @param array [Ast::ArrayValue]
      # @param sort_index [Numeric]
      # @param order [Integer]
      # @return [Ast::ArrayValue]
      def sort_rows(array, sort_index, order)
        column_index = Integer(sort_index) - 1
        raise ArgumentError, 'SORT column index is out of range' unless column_index.between?(0, array.column_count - 1)

        Ast::ArrayValue.new(stable_sort(array.rows, order) { |row| row.fetch(column_index) })
      end

      # Sorts a table by one row.
      #
      # @param array [Ast::ArrayValue]
      # @param sort_index [Numeric]
      # @param order [Integer]
      # @return [Ast::ArrayValue]
      def sort_columns(array, sort_index, order)
        row_index = Integer(sort_index) - 1
        raise ArgumentError, 'SORT row index is out of range' unless row_index.between?(0, array.row_count - 1)

        columns = (1..array.column_count).map { |index| array.column(index) }
        Ast::ArrayValue.new(stable_sort(columns, order) { |column| column.fetch(row_index) }.transpose)
      end

      # Performs a stable sort while preserving original order for ties.
      #
      # @param values [Array<Object>]
      # @param order [Integer]
      # @yieldparam value [Object]
      # @return [Array<Object>]
      def stable_sort(values, order)
        values.each_with_index
              .sort do |(left, left_index), (right, right_index)|
                comparison = compare_sort_values(yield(left), yield(right))
                comparison *= order
                comparison.zero? ? left_index <=> right_index : comparison
              end
              .map(&:first)
      end

      # Compares two values using the array sort semantics.
      #
      # @param left [Object]
      # @param right [Object]
      # @return [Integer, nil]
      def compare_sort_values(left, right)
        sort_key(left) <=> sort_key(right)
      end

      # Converts a value into a sortable tuple.
      #
      # @param value [Object]
      # @return [Array<Object>]
      def sort_key(value)
        case value
        when Numeric
          [0, BigDecimal(value.to_s)]
        when String
          [1, value]
        when true
          [2, 1]
        when false
          [2, 0]
        when NilClass
          [3, '']
        else
          [4, value.to_s]
        end
      end

      # Determines whether FILTER should include rows or columns.
      #
      # @param array [Ast::ArrayValue]
      # @param mask [Ast::ArrayValue]
      # @return [Symbol]
      def filter_dimension(array, mask)
        raise ArgumentError, 'FILTER expects a 1D include array' unless mask.vector?

        if array.row_vector?
          return :columns if mask.vector_values.length == array.column_count
        elsif array.column_vector?
          return :rows if mask.vector_values.length == array.row_count
        else
          return :rows if mask.column_vector? && mask.row_count == array.row_count
          return :columns if mask.row_vector? && mask.column_count == array.column_count
        end

        raise ArgumentError, 'FILTER include array shape does not match the input array'
      end

      # Filters table rows using a mask vector.
      #
      # @param array [Ast::ArrayValue]
      # @param mask_values [Array<Object>]
      # @return [Ast::ArrayValue, nil]
      def filter_rows(array, mask_values)
        rows = array.rows.each_with_index.filter_map { |row, index| row if mask_values.fetch(index) }
        return if rows.empty?

        Ast::ArrayValue.new(rows)
      end

      # Filters table columns using a mask vector.
      #
      # @param array [Ast::ArrayValue]
      # @param mask_values [Array<Object>]
      # @return [Ast::ArrayValue, nil]
      def filter_columns(array, mask_values)
        column_indexes = mask_values.each_index.select { |index| mask_values.fetch(index) }
        return if column_indexes.empty?

        rows = array.rows.map do |row|
          column_indexes.map { |index| row.fetch(index) }
        end

        Ast::ArrayValue.new(rows)
      end

      # Rebuilds a vector using the orientation of the original array.
      #
      # @param values [Array<Object>]
      # @param original [Ast::ArrayValue]
      # @return [Ast::ArrayValue]
      def vector_array(values, original)
        original.row_vector? ? Ast::ArrayValue.row(values) : Ast::ArrayValue.column(values)
      end

      # Returns whether two values can be compared.
      #
      # @param left [Object]
      # @param right [Object]
      # @return [Boolean]
      def comparable?(left, right)
        left.respond_to?(:<=>) && !(left <=> right).nil?
      end

      # Normalizes the MATCH mode argument.
      #
      # @param match_type [Numeric]
      # @return [Integer]
      def normalize_match_type(match_type)
        match_type = Integer(match_type)
        return match_type if [1, 0, -1].include?(match_type)

        raise ArgumentError, 'MATCH match type must be -1, 0, or 1'
      end

      # Normalizes the XLOOKUP match mode argument.
      #
      # @param match_mode [Numeric]
      # @return [Integer]
      def normalize_xlookup_match_mode(match_mode)
        match_mode = Integer(match_mode)
        return match_mode if [-1, 0, 1].include?(match_mode)

        raise ArgumentError, 'XLOOKUP match mode must be -1, 0, or 1'
      end
    end
  end
end
