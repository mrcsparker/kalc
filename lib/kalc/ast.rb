# Abstract syntax tree and runtime values for Kalc.
module Kalc
  # Namespace for AST nodes and runtime value objects.
  module Ast
    # Wraps an expression so it can be re-evaluated lazily like a spreadsheet cell.
    class Formula
      attr_reader :expression, :name

      # @param expression [Object]
      # @param name [String, nil]
      def initialize(expression, name = nil)
        @expression = expression
        @name = name
      end

      # Evaluates the formula in the given execution context.
      #
      # @param context [Environment]
      # @return [Object]
      def eval(context)
        context.with_formula(self, @name) { @expression.eval(context) }
      end
    end

    # Root node for a parsed program.
    class Program
      attr_reader :statements

      # @param statements [Array<Object>]
      def initialize(statements)
        @statements = statements.freeze
      end

      # Evaluates each statement in order and returns the last result.
      #
      # @param context [Environment]
      # @return [Object]
      def eval(context)
        @statements.reduce(nil) { |_last, statement| statement.eval(context) }
      end
    end

    # Base class for scalar literal nodes.
    class Literal
      attr_reader :value

      # @param value [Object]
      def initialize(value)
        @value = value
      end

      # Returns the literal value unchanged.
      #
      # @param _context [Environment]
      # @return [Object]
      def eval(_context)
        @value
      end
    end

    # Numeric literal backed by {BigDecimal}.
    class NumericLiteral < Literal
      # @param value [String, Numeric]
      def initialize(value)
        super(BigDecimal(value.to_s))
      end
    end

    # String literal node.
    class StringLiteral < Literal
    end

    # Boolean literal node.
    class BooleanLiteral < Literal
      # @param value [String, Boolean]
      def initialize(value)
        super(value == 'TRUE')
      end
    end

    # Runtime value for rectangular spreadsheet-style arrays.
    class ArrayValue
      attr_reader :rows

      # Builds a one-column array.
      #
      # @param values [Array<Object>]
      # @return [ArrayValue]
      def self.column(values)
        new(values.map { |value| [value] })
      end

      # Builds a one-row array.
      #
      # @param values [Array<Object>]
      # @return [ArrayValue]
      def self.row(values)
        new([values])
      end

      # @param rows [Array<Array<Object>>]
      def initialize(rows)
        @rows = rows.map(&:freeze).freeze
      end

      # @return [Integer]
      def row_count
        @rows.length
      end

      # @return [Integer]
      def column_count
        @rows.first.length
      end

      # @return [Boolean]
      def row_vector?
        row_count == 1
      end

      # @return [Boolean]
      def column_vector?
        column_count == 1
      end

      # @return [Boolean]
      def vector?
        row_vector? || column_vector?
      end

      # Flattens the array to row-major scalar values.
      #
      # @return [Array<Object>]
      def flat_values
        @rows.flatten(1)
      end

      # Returns the values for a one-dimensional array.
      #
      # @return [Array<Object>]
      def vector_values
        raise ArgumentError, 'Expected a 1D array' unless vector?

        row_vector? ? @rows.first : @rows.map(&:first)
      end

      # Fetches a one-based row.
      #
      # @param index [Integer]
      # @return [Array<Object>]
      def row(index)
        @rows.fetch(index - 1)
      rescue IndexError
        raise ArgumentError, 'Array row is out of range'
      end

      # Fetches a one-based column.
      #
      # @param index [Integer]
      # @return [Array<Object>]
      def column(index)
        @rows.map { |row| row.fetch(index - 1) }
      rescue IndexError
        raise ArgumentError, 'Array column is out of range'
      end

      # Fetches a scalar from the array using Excel-like indexing rules.
      #
      # @param row_index [Integer]
      # @param column_index [Integer, nil]
      # @return [Object]
      def value_at(row_index, column_index = nil)
        if column_index.nil?
          return @rows.first.fetch(row_index - 1) if row_count == 1
          return @rows.fetch(row_index - 1).first if column_count == 1

          raise ArgumentError, 'INDEX needs both row and column for a 2D array'
        end

        @rows.fetch(row_index - 1).fetch(column_index - 1)
      rescue IndexError
        raise ArgumentError, 'INDEX is out of range'
      end

      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        other.is_a?(ArrayValue) && @rows == other.rows
      end

      # @return [ArrayValue]
      def transpose
        ArrayValue.new(@rows.transpose)
      end

      # @return [String]
      def to_s
        "[#{@rows.map { |row| format_row(row) }.join('; ')}]"
      end

      alias inspect to_s

      private

      # @param row [Array<Object>]
      # @return [String]
      def format_row(row)
        row.map { |value| format_value(value) }.join(', ')
      end

      # @param value [Object]
      # @return [String]
      def format_value(value)
        case value
        when String
          value.inspect
        when BigDecimal
          value.to_s('F')
        else
          value.to_s
        end
      end
    end

    # AST node for array literals.
    class ArrayLiteral
      attr_reader :rows

      # @param rows [Array<Array<Object>>]
      def initialize(rows)
        @rows = rows.map(&:freeze).freeze
      end

      # Evaluates each element in the literal and returns an {ArrayValue}.
      #
      # @param context [Environment]
      # @return [ArrayValue]
      def eval(context)
        ArrayValue.new(@rows.map { |row| row.map { |value| value.eval(context) } })
      end
    end

    # AST node for prefix unary operators.
    class UnaryOperation
      attr_reader :operator, :operand

      # @param operator [String]
      # @param operand [Object]
      def initialize(operator, operand)
        @operator = operator
        @operand = operand
      end

      # Evaluates the unary expression.
      #
      # @param context [Environment]
      # @return [Object]
      def eval(context)
        case @operator
        when '+'
          +@operand.eval(context)
        when '-'
          -@operand.eval(context)
        else
          raise "Unknown unary operator #{@operator.inspect}"
        end
      end
    end

    # AST node for infix binary operators.
    class BinaryOperation
      attr_reader :left, :right, :operator

      # @param left [Object]
      # @param right [Object]
      # @param operator [String]
      def initialize(left, right, operator)
        @left = left
        @right = right
        @operator = operator
      end

      # Evaluates the binary expression.
      #
      # Logical operators short-circuit so spreadsheet formulas and side effects
      # behave like Ruby and Excel users expect.
      #
      # @param context [Environment]
      # @return [Object]
      def eval(context)
        left = @left.eval(context)

        case @operator
        when '&&', 'and'
          left && @right.eval(context)
        when '||', 'or'
          left || @right.eval(context)
        else
          evaluate_non_logical(left, context)
        end
      end

      private

      # Evaluates a non-logical binary operator after the left operand is known.
      #
      # @param left [Object]
      # @param context [Environment]
      # @return [Object]
      def evaluate_non_logical(left, context)
        right = @right.eval(context)

        case @operator
        when '<='
          left <= right
        when '>='
          left >= right
        when '=', '=='
          left == right
        when '!='
          left != right
        when '-'
          left - right
        when '+'
          left + right
        when '^'
          left**right
        when '*'
          left * right
        when '/'
          left / right
        when '%'
          left % right
        when '<'
          left < right
        when '>'
          left > right
        else
          raise "Unknown binary operator #{@operator.inspect}"
        end
      end
    end

    # AST node for ternary conditionals.
    class Conditional
      attr_reader :condition, :if_true, :if_false

      # @param condition [Object]
      # @param if_true [Object]
      # @param if_false [Object]
      def initialize(condition, if_true, if_false)
        @condition = condition
        @if_true = if_true
        @if_false = if_false
      end

      # @param context [Environment]
      # @return [Object]
      def eval(context)
        @condition.eval(context) ? @if_true.eval(context) : @if_false.eval(context)
      end
    end

    # AST node for lazy variable assignment.
    class Assignment
      attr_reader :name, :expression

      # @param name [String, Symbol]
      # @param expression [Object]
      def initialize(name, expression)
        @name = name.to_s.strip
        @expression = expression
      end

      # Stores a formula and returns its evaluated value.
      #
      # @param context [Environment]
      # @return [Object]
      def eval(context)
        formula = Formula.new(@expression, @name)
        context.add_variable(@name, formula)
        formula.eval(context)
      end
    end

    # AST node for variable reads.
    class VariableReference
      attr_reader :name

      # @param name [String]
      def initialize(name)
        @name = name
      end

      # @param context [Environment]
      # @return [Object]
      def eval(context)
        value = context.get_variable(@name)
        raise "Invalid variable: #{@name}" if value.equal?(Environment::MISSING)

        value.is_a?(Formula) ? value.eval(context) : value
      end
    end

    # AST node for function invocation.
    class FunctionCall
      attr_reader :name, :arguments

      # @param name [String]
      # @param arguments [Array<Object>]
      def initialize(name, arguments)
        @name = name
        @arguments = arguments.freeze
      end

      # @param context [Environment]
      # @return [Object]
      def eval(context)
        function = context.get_function(@name)
        raise "Unknown function #{@name}" if function.equal?(Environment::MISSING)

        validate_arity!(function)
        function.call(context, *@arguments)
      end

      private

      # Validates the argument count against the callable signature.
      #
      # @param function [Object]
      # @return [void]
      def validate_arity!(function)
        return unless function.respond_to?(:arity)

        arity = function.arity
        return if arity.accepts?(@arguments.count)

        raise "Argument Error. Function #{@name} was called with #{@arguments.count} parameters. " \
              "#{arity.expected_message}"
      end
    end

    # Runtime value for user-defined functions.
    class UserFunction
      attr_reader :parameter_names, :arity

      # @param parameters [Array<String>]
      # @param body [Program]
      def initialize(parameters, body)
        @parameter_names = parameters.freeze
        @body = body
        @arity = FunctionArity.new(required: @parameter_names.length)
      end

      # Evaluates the function body in a child environment.
      #
      # @param parent_context [Environment]
      # @param arguments [Array<Object>]
      # @return [Object]
      def call(parent_context, *arguments)
        child_context = Environment.new(parent_context)

        @parameter_names.each_with_index do |parameter, index|
          child_context.add_variable(parameter, arguments.fetch(index).eval(parent_context))
        end

        @body.eval(child_context)
      end
    end

    # AST node for function definitions.
    class FunctionDefinition
      attr_reader :name, :parameters, :body

      # @param name [String]
      # @param parameters [Array<String>]
      # @param body [Program]
      def initialize(name, parameters, body)
        @name = name
        @parameters = parameters.freeze
        @body = body
      end

      # Registers the function in the current environment.
      #
      # @param context [Environment]
      # @return [nil]
      def eval(context)
        context.add_function(@name.to_sym, UserFunction.new(@parameters, @body))
        nil
      end
    end
  end
end
