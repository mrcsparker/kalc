# Recursive-descent parser for Kalc expressions and function definitions.
module Kalc
  # Parses Kalc source into AST programs.
  class Grammar
    # Recursive-descent parser over lexer tokens.
    class Parser
      # @param tokens [Array<Grammar::Token>]
      # @param source [String]
      def initialize(tokens, source)
        @tokens = tokens
        @source = source
        @index = 0
      end

      # Parses the full token stream into an {Ast::Program}.
      #
      # @return [Ast::Program]
      def parse
        commands = parse_sequence(terminator: :eof, allow_function_definitions: true)
        expect(:eof)
        commands
      end

      private

      # Parses a statement sequence until the given terminator token.
      #
      # @param terminator [Symbol]
      # @param allow_function_definitions [Boolean]
      # @return [Ast::Program]
      def parse_sequence(terminator:, allow_function_definitions:)
        commands = []
        skip_statement_separators

        until current.type == terminator
          commands << parse_statement(allow_function_definitions: allow_function_definitions)
          break if current.type == terminator

          if separator?(current)
            skip_statement_separators
            next
          end

          raise unexpected_token('a statement separator')
        end

        Ast::Program.new(commands)
      end

      # Parses a single top-level statement.
      #
      # @param allow_function_definitions [Boolean]
      # @return [Object]
      def parse_statement(allow_function_definitions:)
        return parse_function_definition if allow_function_definitions && match?(:define)

        parse_expression
      end

      # Parses a function definition statement.
      #
      # @return [Ast::FunctionDefinition]
      def parse_function_definition
        expect(:define)
        skip_newlines
        name = expect(:identifier).value
        skip_newlines
        expect(:left_paren)
        skip_newlines
        arguments = parse_argument_list
        skip_newlines
        expect(:right_paren)
        skip_newlines
        expect(:left_brace)
        body = parse_sequence(terminator: :right_brace, allow_function_definitions: false)
        expect(:right_brace)

        Ast::FunctionDefinition.new(name, arguments, body)
      end

      # Parses the parameter list for a function definition.
      #
      # @return [Array<String>]
      def parse_argument_list
        return [] if match?(:right_paren)

        first = expect(:identifier).value
        arguments = [first]

        while match?(:comma)
          advance
          skip_newlines
          arguments << expect(:identifier).value
        end

        arguments
      end

      # Parses the highest-precedence expression entry point.
      #
      # @return [Object]
      def parse_expression
        parse_assignment
      end

      # Parses right-associative assignment expressions.
      #
      # @return [Object]
      def parse_assignment
        if variable_token?(current) && peek.type == :assign
          identifier = advance.value
          advance
          skip_newlines
          return Ast::Assignment.new(identifier, parse_assignment)
        end

        parse_conditional
      end

      # Parses ternary conditional expressions.
      #
      # @return [Object]
      def parse_conditional
        condition = parse_logical_or
        return condition unless match?(:question_mark)

        advance
        skip_newlines
        true_cond = parse_conditional
        skip_newlines
        expect(:colon)
        skip_newlines
        false_cond = parse_conditional

        Ast::Conditional.new(condition, true_cond, false_cond)
      end

      # Parses logical OR expressions.
      #
      # @return [Object]
      def parse_logical_or
        parse_left_associative(:parse_logical_and, :logical_or, :string_or)
      end

      # Parses logical AND expressions.
      #
      # @return [Object]
      def parse_logical_and
        parse_left_associative(:parse_equality, :logical_and, :string_and)
      end

      # Parses equality expressions.
      #
      # @return [Object]
      def parse_equality
        parse_left_associative(:parse_relational, :excel_equal, :equal, :not_equal)
      end

      # Parses relational expressions.
      #
      # @return [Object]
      def parse_relational
        parse_left_associative(:parse_additive, :less, :greater, :less_equal, :greater_equal)
      end

      # Parses addition and subtraction.
      #
      # @return [Object]
      def parse_additive
        parse_left_associative(:parse_multiplicative, :add, :subtract)
      end

      # Parses multiplication, division, and modulus.
      #
      # @return [Object]
      def parse_multiplicative
        parse_left_associative(:parse_unary, :multiply, :divide, :modulus)
      end

      # Parses a chain of left-associative operators.
      #
      # @param method_name [Symbol]
      # @param operators [Array<Symbol>]
      # @return [Object]
      def parse_left_associative(method_name, *operators)
        expression = send(method_name)

        while operators.include?(current.type)
          operator = advance.value
          skip_newlines
          expression = Ast::BinaryOperation.new(expression, send(method_name), operator)
        end

        expression
      end

      # Parses unary prefix operators.
      #
      # @return [Object]
      def parse_unary
        case current.type
        when :add
          advance
          skip_newlines
          Ast::UnaryOperation.new('+', parse_unary)
        when :subtract
          advance
          skip_newlines
          Ast::UnaryOperation.new('-', parse_unary)
        else
          parse_power
        end
      end

      # Parses exponentiation.
      #
      # @return [Object]
      def parse_power
        left = parse_primary
        return left unless match?(:power_of)

        operator = advance.value
        skip_newlines
        Ast::BinaryOperation.new(left, parse_unary, operator)
      end

      # Parses a primary expression.
      #
      # @return [Object]
      def parse_primary
        case current.type
        when :left_paren
          parse_paren_expression
        when :left_bracket
          parse_array_literal
        when :boolean
          Ast::BooleanLiteral.new(advance.value)
        when :number
          Ast::NumericLiteral.new(advance.value)
        when :string
          Ast::StringLiteral.new(advance.value)
        when :identifier
          parse_identifier_expression
        when :quoted_identifier
          Ast::VariableReference.new(advance.value)
        else
          raise unexpected_token('an expression')
        end
      end

      # Parses a parenthesized expression.
      #
      # @return [Object]
      def parse_paren_expression
        expect(:left_paren)
        skip_newlines
        expression = parse_conditional
        skip_newlines
        expect(:right_paren)
        expression
      end

      # Parses an array literal.
      #
      # @return [Ast::ArrayLiteral]
      def parse_array_literal
        expect(:left_bracket)
        skip_newlines

        rows = [parse_array_row]

        while match?(:separator)
          advance
          skip_newlines
          rows << parse_array_row
        end

        skip_newlines
        expect(:right_bracket)
        validate_array_rows!(rows)

        Ast::ArrayLiteral.new(rows)
      end

      # Parses one row inside an array literal.
      #
      # @return [Array<Object>]
      def parse_array_row
        values = [parse_conditional]

        while match?(:comma)
          advance
          skip_newlines
          values << parse_conditional
        end

        values
      end

      # Parses a variable reference or function call.
      #
      # @return [Object]
      def parse_identifier_expression
        identifier = advance.value
        return Ast::VariableReference.new(identifier) unless match?(:left_paren)

        advance
        skip_newlines
        arguments = parse_call_arguments
        skip_newlines
        expect(:right_paren)

        Ast::FunctionCall.new(identifier, arguments)
      end

      # Parses the argument list for a function call.
      #
      # @return [Array<Object>]
      def parse_call_arguments
        return [] if match?(:right_paren)

        arguments = [parse_conditional]

        while match?(:comma)
          advance
          skip_newlines
          arguments << parse_conditional
        end

        arguments
      end

      # Verifies that all array rows have the same width.
      #
      # @param rows [Array<Array<Object>>]
      # @return [void]
      def validate_array_rows!(rows)
        expected_width = rows.first.length
        return if rows.all? { |row| row.length == expected_width }

        raise ParseError.new(@source, current.position, 'Array rows must all have the same number of columns')
      end

      # Skips all newline and semicolon separators.
      #
      # @return [void]
      def skip_statement_separators
        advance while separator?(current)
      end

      # Skips newline tokens.
      #
      # @return [void]
      def skip_newlines
        advance while match?(:newline)
      end

      # Returns whether the token separates statements.
      #
      # @param token [Grammar::Token]
      # @return [Boolean]
      def separator?(token)
        %i[newline separator].include?(token.type)
      end

      # Returns whether the token can appear on the left side of an assignment.
      #
      # @param token [Grammar::Token]
      # @return [Boolean]
      def variable_token?(token)
        %i[identifier quoted_identifier].include?(token.type)
      end

      # Returns whether the current token has the given type.
      #
      # @param type [Symbol]
      # @return [Boolean]
      def match?(type)
        current.type == type
      end

      # Consumes the current token if it matches the expected type.
      #
      # @param type [Symbol]
      # @return [Grammar::Token]
      def expect(type)
        return advance if match?(type)

        raise unexpected_token(type.to_s.tr('_', ' '))
      end

      # Returns the current token.
      #
      # @return [Grammar::Token]
      def current
        @tokens[@index]
      end

      # Returns a lookahead token.
      #
      # @param offset [Integer]
      # @return [Grammar::Token]
      def peek(offset = 1)
        @tokens[@index + offset] || @tokens.last
      end

      # Advances to the next token.
      #
      # @return [Grammar::Token]
      def advance
        token = current
        @index += 1 unless current.type == :eof
        token
      end

      # Builds an error for an unexpected token at the current position.
      #
      # @param expected [String]
      # @return [ParseError]
      def unexpected_token(expected)
        actual = current.type == :eof ? 'end of input' : current.value.inspect
        ParseError.new(@source, current.position, "Expected #{expected}, got #{actual}")
      end
    end
  end
end
