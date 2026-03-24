# Numeric, aggregate, and criteria-based builtin functions.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Numeric and aggregate spreadsheet functions.
    module Math
      module_function

      MATH_FUNCTIONS = %w[
        acos acosh asin asinh atan atanh cbrt cos cosh erf erfc exp gamma
        lgamma log log2 log10 sin sinh sqrt tan tanh
      ].freeze

      # Registers the math builtin functions.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_eager(env, :ABS, &:abs)
        Helpers.define_eager(env, :AVERAGE) { |first, *rest| average(Helpers.scalar_values([first, *rest])) }
        Helpers.define_eager(env, :COUNT) { |first, *rest| count_numbers(Helpers.scalar_values([first, *rest])) }
        Helpers.define_eager(env, :COUNTA) { |first, *rest| count_non_empty(Helpers.scalar_values([first, *rest])) }
        Helpers.define_eager(env, :DEGREES) { |value| value * (180.0 / ::Math::PI) }
        Helpers.define_eager(env, :INT) { |value| integer_floor(value) }
        Helpers.define_eager(env, :MOD) { |number, divisor| number % divisor }
        Helpers.define_eager(env, :MROUND) { |number, multiple| round_to_multiple(number, multiple) }
        Helpers.define_eager(env, :PI) { ::Math::PI }
        Helpers.define_eager(env, :PRODUCT) { |*values| Helpers.scalar_values(values).reduce(:*) }
        Helpers.define_eager(env, :POWER) { |number, exponent| number**exponent }
        Helpers.define_eager(env, :QUOTIENT) { |numerator, denominator| quotient(numerator, denominator) }
        Helpers.define_eager(env, :RADIANS) { |value| value * (::Math::PI / 180.0) }
        Helpers.define_eager(env, :RANDBETWEEN) { |lower, upper| random_between(lower, upper) }
        Helpers.define_eager(env, :ROUND) { |number, digits| number.round(digits.to_i) }
        Helpers.define_eager(env, :ROUNDDOWN) { |number, digits| round_with_mode(number, digits, BigDecimal::ROUND_DOWN) }
        Helpers.define_eager(env, :ROUNDUP) { |number, digits| round_with_mode(number, digits, BigDecimal::ROUND_UP) }
        Helpers.define_eager(env, :SIGN) { |value| sign(value) }
        Helpers.define_eager(env, :SUMIF) { |range, criteria, sum_range = nil| sum_if(range, criteria, sum_range) }
        Helpers.define_eager(env, :SUM) { |*values| Helpers.scalar_values(values).reduce(:+) }
        Helpers.define_eager(env, :TRUNC) { |value| Integer(value) }
        Helpers.define_eager(env, :COUNTIF) { |range, criteria| count_if(range, criteria) }
        Helpers.define_eager(env, :LN) { |value| ::Math.log(value) }

        Helpers.define_eager(env, :MAX) do |first, *rest|
          values = Helpers.scalar_values([first, *rest])
          if values.any? { |value| Helpers.special_numeric?(value) && value.nan? }
            BigDecimal('NaN')
          else
            values.max
          end
        end

        Helpers.define_eager(env, :MIN) do |first, *rest|
          values = Helpers.scalar_values([first, *rest])
          if values.any? { |value| Helpers.special_numeric?(value) && value.nan? }
            BigDecimal('NaN')
          else
            values.min
          end
        end

        MATH_FUNCTIONS.each do |function_name|
          Helpers.define_eager(env, function_name.upcase.to_sym) do |value|
            ::Math.public_send(function_name, value)
          end
        end

        Helpers.define_eager(env, :FLOOR) do |value|
          Helpers.special_numeric?(value) ? value : value.floor
        end

        Helpers.define_eager(env, :CEILING) do |value|
          Helpers.special_numeric?(value) ? value : value.ceil
        end
      end

      # Returns the average value from a scalar list.
      #
      # @param values [Array<Numeric>]
      # @return [Numeric]
      def average(values)
        values.reduce(:+) / decimal(values.length)
      end

      # Sums values whose paired range entries match the given criteria.
      #
      # @param range [Object]
      # @param criteria [Object]
      # @param sum_range [Object, nil]
      # @return [Numeric]
      def sum_if(range, criteria, sum_range)
        range_values = Helpers.scalar_values([range])
        sum_values = sum_range.nil? ? range_values : parallel_values(range, sum_range, :SUMIF)
        matcher = criteria_matcher(criteria)

        sum_values.each_with_index.reduce(decimal(0)) do |total, (value, index)|
          next total unless matcher.call(range_values.fetch(index))
          next total unless value.is_a?(Numeric)

          total + value
        end
      end

      # Counts values that match the given criteria.
      #
      # @param range [Object]
      # @param criteria [Object]
      # @return [Integer]
      def count_if(range, criteria)
        matcher = criteria_matcher(criteria)
        Helpers.scalar_values([range]).count { |value| matcher.call(value) }
      end

      # Counts numeric entries in a flattened value list.
      #
      # @param values [Array<Object>]
      # @return [Integer]
      def count_numbers(values)
        values.count { |value| value.is_a?(Numeric) }
      end

      # Counts non-nil entries in a flattened value list.
      #
      # @param values [Array<Object>]
      # @return [Integer]
      def count_non_empty(values)
        values.count { |value| !value.nil? }
      end

      # Floors a numeric value while preserving NaN and Infinity.
      #
      # @param value [Numeric]
      # @return [Numeric]
      def integer_floor(value)
        return value if Helpers.special_numeric?(value)

        decimal(value).floor
      end

      # Divides and truncates toward zero.
      #
      # @param numerator [Numeric]
      # @param denominator [Numeric]
      # @return [Integer]
      def quotient(numerator, denominator)
        (decimal(numerator) / decimal(denominator)).truncate
      end

      # Returns a random integer between the inclusive bounds.
      #
      # @param lower [Numeric]
      # @param upper [Numeric]
      # @return [Integer]
      def random_between(lower, upper)
        minimum = Integer(lower)
        maximum = Integer(upper)
        raise ArgumentError, 'RANDBETWEEN lower bound must be less than or equal to upper bound' if minimum > maximum

        rand(minimum..maximum)
      end

      # Rounds a number with an explicit BigDecimal rounding mode.
      #
      # @param number [Numeric]
      # @param digits [Numeric]
      # @param mode [Integer]
      # @return [Numeric]
      def round_with_mode(number, digits, mode)
        return number if Helpers.special_numeric?(number)

        decimal(number).round(Integer(digits), mode)
      end

      # Rounds a number to the nearest multiple.
      #
      # @param number [Numeric]
      # @param multiple [Numeric]
      # @return [Numeric]
      def round_to_multiple(number, multiple)
        value = decimal(number)
        significance = decimal(multiple)
        raise ZeroDivisionError, 'divided by 0' if significance.zero?

        (value / significance).round(0, BigDecimal::ROUND_HALF_UP) * significance
      end

      # Returns -1, 0, or 1 for the sign of a number.
      #
      # @param value [Numeric]
      # @return [Numeric]
      def sign(value)
        return value if Helpers.special_numeric?(value)

        comparable = decimal(value)
        return 1 if comparable.positive?
        return -1 if comparable.negative?

        0
      end

      # Coerces a numeric-like value to {BigDecimal}.
      #
      # @param value [Object]
      # @return [BigDecimal]
      def decimal(value)
        value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
      end

      # Returns flattened parallel arrays after validating their shapes.
      #
      # @param range [Object]
      # @param sum_range [Object]
      # @param function_name [String, Symbol]
      # @return [Array<Object>]
      def parallel_values(range, sum_range, function_name)
        validate_parallel_shapes!(range, sum_range, function_name)

        range_values = Helpers.scalar_values([range])
        sum_values = Helpers.scalar_values([sum_range])
        return sum_values if range_values.length == sum_values.length

        raise ArgumentError, "#{function_name} range and sum_range must have the same size"
      end

      # Ensures that two scalar-or-array inputs have the same shape.
      #
      # @param range [Object]
      # @param sum_range [Object]
      # @param function_name [String, Symbol]
      # @return [void]
      def validate_parallel_shapes!(range, sum_range, function_name)
        return if value_shape(range) == value_shape(sum_range)

        raise ArgumentError, "#{function_name} range and sum_range must have the same shape"
      end

      # Builds a predicate proc for COUNTIF and SUMIF criteria.
      #
      # @param criteria [Object]
      # @return [Proc]
      def criteria_matcher(criteria)
        operator, operand = parse_criteria(criteria)

        case operator
        when nil, '=', '=='
          equality_matcher(criteria, operand)
        when '<>', '!='
          inequality_matcher(criteria, operand)
        when '>'
          comparison_matcher(operand, :>)
        when '>='
          comparison_matcher(operand, :>=)
        when '<'
          comparison_matcher(operand, :<)
        when '<='
          comparison_matcher(operand, :<=)
        else
          raise ArgumentError, "Unsupported criteria operator #{operator.inspect}"
        end
      end

      # Splits a criteria value into an operator and operand.
      #
      # @param criteria [Object]
      # @return [Array<Object>]
      def parse_criteria(criteria)
        return [nil, criteria] unless criteria.is_a?(String)

        match = criteria.match(/\A(<=|>=|<>|!=|=|==|<|>)(.*)\z/)
        return [nil, criteria] unless match

        [match[1], coerce_criteria_operand(match[2].strip)]
      end

      # Builds an equality matcher that preserves plain text semantics.
      #
      # @param criteria [Object]
      # @param operand [Object]
      # @return [Proc]
      def equality_matcher(criteria, operand)
        return ->(value) { value == operand } unless plain_text_criteria?(criteria)

        lambda do |value|
          next value == criteria if value.is_a?(String)

          value == operand
        end
      end

      # Builds an inequality matcher that preserves plain text semantics.
      #
      # @param criteria [Object]
      # @param operand [Object]
      # @return [Proc]
      def inequality_matcher(criteria, operand)
        return ->(value) { value != operand } unless plain_text_criteria?(criteria)

        lambda do |value|
          next value != criteria if value.is_a?(String)

          value != operand
        end
      end

      # Returns whether the criteria is plain text rather than an operator expression.
      #
      # @param criteria [Object]
      # @return [Boolean]
      def plain_text_criteria?(criteria)
        criteria.is_a?(String) && criteria !~ /\A(<=|>=|<>|!=|=|==|<|>)/
      end

      # Coerces criteria operands into booleans or numbers when appropriate.
      #
      # @param value [Object]
      # @return [Object]
      def coerce_criteria_operand(value)
        return value unless value.is_a?(String)

        return true if value.upcase == 'TRUE'
        return false if value.upcase == 'FALSE'
        return BigDecimal(value) if value.match?(/\A[+-]?(?:\d+\.\d+|\d+|\.\d+)(?:[eE][+-]?\d+)?\z/)

        value
      end

      # Builds a relational comparison matcher.
      #
      # @param operand [Object]
      # @param operator [Symbol]
      # @return [Proc]
      def comparison_matcher(operand, operator)
        lambda do |value|
          next false unless value.respond_to?(:<=>)

          comparison = value <=> operand
          next false if comparison.nil?

          comparison.public_send(operator, 0)
        end
      end

      # Returns a comparable shape tuple for scalars and arrays.
      #
      # @param value [Object]
      # @return [Array<Integer>]
      def value_shape(value)
        return [value.row_count, value.column_count] if Helpers.array_value?(value)

        [1, 1]
      end
    end
  end
end
