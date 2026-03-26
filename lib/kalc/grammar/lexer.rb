require 'strscan'

# Tokenizes raw Kalc source into {Grammar::Token} objects.
module Kalc
  # Converts Kalc source text into a token stream.
  class Grammar
    # Streaming lexer backed by {StringScanner}.
    class Lexer
      SINGLE_CHAR_TOKENS = {
        '(' => :left_paren,
        ')' => :right_paren,
        '[' => :left_bracket,
        ']' => :right_bracket,
        '{' => :left_brace,
        '}' => :right_brace,
        ',' => :comma,
        ':' => :colon,
        ';' => :separator,
        '?' => :question_mark,
        '+' => :add,
        '-' => :subtract,
        '*' => :multiply,
        '/' => :divide,
        '%' => :modulus,
        '^' => :power_of,
        '<' => :less,
        '>' => :greater,
        '=' => :excel_equal
      }.freeze

      MULTI_CHAR_TOKENS = {
        ':=' => :assign,
        '==' => :equal,
        '!=' => :not_equal,
        '<=' => :less_equal,
        '>=' => :greater_equal,
        '&&' => :logical_and,
        '||' => :logical_or
      }.freeze

      IDENTIFIER = /[A-Za-z_][A-Za-z0-9_]*/
      NUMBER = /(?:\d+\.\d+|\d+|\.\d+)(?:[eE][+-]?\d+)?/

      # @param source [String]
      def initialize(source)
        @source = source
        @scanner = StringScanner.new(source)
      end

      # Converts the source text into a token stream.
      #
      # @return [Array<Grammar::Token>]
      def tokenize
        tokens = []

        until @scanner.eos?
          skip_horizontal_whitespace
          break if @scanner.eos?

          position = @scanner.pos

          if (token = read_newline(position) ||
                      read_multi_char_operator(position) ||
                      read_word(position) ||
                      read_number(position))
            tokens << token
          elsif @scanner.peek(1) == '"'
            tokens << Token.new(type: :string, value: read_string, position: position)
          elsif @scanner.peek(1) == "'"
            tokens << Token.new(type: :quoted_identifier, value: read_quoted_identifier, position: position)
          else
            tokens << read_single_char_token(position)
          end
        end

        tokens << Token.new(type: :eof, value: nil, position: @scanner.pos)
      end

      private

      # Skips non-newline whitespace between tokens.
      #
      # @return [void]
      def skip_horizontal_whitespace
        @scanner.scan(/[ \t\f\v]+/)
      end

      # Reads a newline token when present.
      #
      # @param position [Integer]
      # @return [Grammar::Token, nil]
      def read_newline(position)
        matched = @scanner.scan(/\r\n|\n|\r/)
        return unless matched

        Token.new(type: :newline, value: matched, position: position)
      end

      # Reads a multi-character operator token when present.
      #
      # @param position [Integer]
      # @return [Grammar::Token, nil]
      def read_multi_char_operator(position)
        MULTI_CHAR_TOKENS.each do |lexeme, type|
          next unless @scanner.scan(Regexp.new(Regexp.escape(lexeme)))

          return Token.new(type: type, value: lexeme, position: position)
        end

        nil
      end

      # Reads identifiers, keywords, and textual operators.
      #
      # @param position [Integer]
      # @return [Grammar::Token, nil]
      def read_word(position)
        word = @scanner.scan(IDENTIFIER)
        return unless word

        case word
        when 'DEFINE'
          Token.new(type: :define, value: word, position: position)
        when 'TRUE', 'FALSE'
          Token.new(type: :boolean, value: word, position: position)
        when 'and'
          Token.new(type: :string_and, value: word, position: position)
        when 'or'
          Token.new(type: :string_or, value: word, position: position)
        else
          Token.new(type: :identifier, value: word, position: position)
        end
      end

      # Reads a numeric literal token when present.
      #
      # @param position [Integer]
      # @return [Grammar::Token, nil]
      def read_number(position)
        number = @scanner.scan(NUMBER)
        return unless number

        Token.new(type: :number, value: number, position: position)
      end

      # Reads an Excel-style double-quoted string literal.
      #
      # Embedded quotes are written as "" inside the string. Backslashes are
      # treated as ordinary characters rather than escape prefixes.
      #
      # @return [String]
      def read_string
        @scanner.getch
        buffer = +''

        loop do
          raise parse_error('Unterminated string literal') if @scanner.eos?

          char = @scanner.getch

          if char == '"'
            if @scanner.peek(1) == '"'
              @scanner.getch
              buffer << '"'
              next
            end

            break
          end

          buffer << char
        end

        buffer
      end

      # Reads a single-quoted identifier.
      #
      # @return [String]
      def read_quoted_identifier
        start = @scanner.pos
        @scanner.getch

        loop do
          raise parse_error('Unterminated quoted identifier') if @scanner.eos?

          char = @scanner.getch
          if char == '\\'
            raise parse_error('Unterminated quoted identifier') if @scanner.eos?

            @scanner.getch
            next
          end

          break if char == "'"
        end

        @source[start...@scanner.pos]
      end

      # Reads a single-character token or raises for an unknown character.
      #
      # @param position [Integer]
      # @return [Grammar::Token]
      def read_single_char_token(position)
        char = @scanner.getch
        type = SINGLE_CHAR_TOKENS[char]
        return Token.new(type: type, value: char, position: position) if type

        raise parse_error("Unexpected character #{char.inspect}")
      end

      # Builds a {ParseError} at the current scanner position.
      #
      # @param message [String]
      # @return [ParseError]
      def parse_error(message)
        ParseError.new(@source, @scanner.pos, message)
      end
    end
  end
end
