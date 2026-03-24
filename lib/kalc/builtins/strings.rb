# Text and formatting builtins.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # String processing and formatting functions.
    module Strings
      module_function

      STRING_METHODS = %w[
        chomp chop chr clear downcase hex inspect intern to_sym length size
        lstrip succ next oct ord reverse rstrip strip swapcase to_c to_f to_i to_r
        upcase
      ].freeze

      # Registers the string builtin functions.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        STRING_METHODS.each do |method_name|
          Helpers.define_eager(env, method_name.upcase.to_sym) do |value|
            String.new(value).public_send(method_name)
          end
        end

        Helpers.define_eager(env, :CHAR) { |value| Integer(value).chr }
        Helpers.define_eager(env, :CLEAN) { |value| value.gsub(/\P{ASCII}/, '') }
        Helpers.define_eager(env, :CODE, &:ord)
        Helpers.define_eager(env, :CONCATENATE) { |*values| Helpers.scalar_values(values).join }
        Helpers.define_eager(env, :DOLLAR) { |value, decimal_places| format_decimal(value, decimal_places) }
        Helpers.define_eager(env, :EXACT) { |left, right| left == right }
        Helpers.define_eager(env, :FIND) do |needle, haystack, starting_pos = 1|
          find_in_string(haystack, needle, starting_pos)
        end
        Helpers.define_eager(env, :FIXED) do |value, decimal_places, no_commas|
          fixed_decimal(value, decimal_places, no_commas)
        end
        Helpers.define_eager(env, :LEFT) { |value, count| value[0..(Integer(count) - 1)] }
        Helpers.define_eager(env, :LEN, &:length)
        Helpers.define_eager(env, :LOWER, &:downcase)
        Helpers.define_eager(env, :MID) do |value, start_position, count|
          middle_of_string(value, start_position, count)
        end
        Helpers.define_eager(env, :PROPER) { |value| value.split.map(&:capitalize).join(' ') }
        Helpers.define_eager(env, :REPLACE) do |value, start_position, count, new_text|
          replace_substring(value, start_position, count, new_text)
        end
        Helpers.define_eager(env, :REPT) { |value, count| value * Integer(count) }
        Helpers.define_eager(env, :RIGHT) { |value, count| value[-Integer(count)..] }
        Helpers.define_eager(env, :SEARCH) do |needle, haystack, start_position = 1|
          search_in_string(haystack, needle, start_position)
        end
        Helpers.define_eager(env, :SUBSTITUTE) do |value, old_text, new_text, instance_num = nil|
          substitute_text(value, old_text, new_text, instance_num)
        end
        Helpers.define_eager(env, :TEXTJOIN) do |delimiter, ignore_empty, *values|
          text_join(delimiter, ignore_empty, values)
        end
        Helpers.define_eager(env, :TRIM, &:strip)
        Helpers.define_eager(env, :UPPER, &:upcase)
        Helpers.define_eager(env, :VALUE, &:to_f)
      end

      # Formats a number using a fixed number of decimal places.
      #
      # @param value [Numeric]
      # @param decimal_places [Numeric]
      # @return [String]
      def format_decimal(value, decimal_places)
        format("%.#{Integer(decimal_places)}f", BigDecimal(value))
      end

      # Returns the one-based position of a substring.
      #
      # @param haystack [String]
      # @param needle [String]
      # @param starting_pos [Numeric]
      # @return [Integer]
      def find_in_string(haystack, needle, starting_pos)
        index = haystack[(Integer(starting_pos) - 1)..].index(needle)
        raise ArgumentError, "Unable to find #{needle.inspect} in #{haystack.inspect}" unless index

        index + Integer(starting_pos)
      end

      # Formats a number with optional thousands separators.
      #
      # @param value [Numeric]
      # @param decimal_places [Numeric]
      # @param no_commas [Boolean]
      # @return [String]
      def fixed_decimal(value, decimal_places, no_commas)
        output = format_decimal(value, decimal_places)
        return output if no_commas

        output.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
      end

      # Returns a substring using Excel-style one-based positions.
      #
      # @param value [String]
      # @param start_position [Numeric]
      # @param count [Numeric]
      # @return [String, nil]
      def middle_of_string(value, start_position, count)
        start = Integer(start_position) - 1
        length = Integer(count) - 1
        value[start..(start + length)]
      end

      # Replaces a slice of text using Excel-style one-based positions.
      #
      # @param value [String]
      # @param start_position [Numeric]
      # @param count [Numeric]
      # @param new_text [String]
      # @return [String]
      def replace_substring(value, start_position, count, new_text)
        output = value.dup
        start = Integer(start_position) - 1
        length = Integer(count) - 1
        output[start..(start + length)] = new_text
        output
      end

      # Case-insensitive version of {#find_in_string}.
      #
      # @param haystack [String]
      # @param needle [String]
      # @param start_position [Numeric]
      # @return [Integer]
      def search_in_string(haystack, needle, start_position)
        start = Integer(start_position) - 1
        index = haystack.downcase[start..].index(needle.downcase)
        raise ArgumentError, "Unable to find #{needle.inspect} in #{haystack.inspect}" unless index

        index + Integer(start_position)
      end

      # Replaces all or one occurrence of a substring.
      #
      # @param value [String]
      # @param old_text [String]
      # @param new_text [String]
      # @param instance_num [Numeric, nil]
      # @return [String]
      def substitute_text(value, old_text, new_text, instance_num)
        return value.gsub(old_text, new_text) if instance_num.nil?

        target = Integer(instance_num)
        raise ArgumentError, 'SUBSTITUTE instance number must be positive' if target <= 0

        occurrence = 0
        value.gsub(old_text) do |match|
          occurrence += 1
          occurrence == target ? new_text : match
        end
      end

      # Joins scalars and array values into one string.
      #
      # @param delimiter [Object]
      # @param ignore_empty [Boolean]
      # @param values [Array<Object>]
      # @return [String]
      def text_join(delimiter, ignore_empty, values)
        Helpers.scalar_values(values)
               .reject { |value| ignore_empty && (value.nil? || value == '') }
               .join(delimiter.to_s)
      end
    end
  end
end
