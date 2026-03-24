# Error raised when Kalc source cannot be tokenized or parsed.
module Kalc
  # Reports a parse failure with line and column details.
  class ParseError < StandardError
    attr_reader :line, :column

    # @param source [String]
    # @param position [Integer]
    # @param message [String]
    def initialize(source, position, message)
      @source = source
      @position = position
      @line, @column = line_and_column
      super(build_message(message))
    end

    private

    # Computes the one-based line and column for the parser offset.
    #
    # @return [Array<Integer>]
    def line_and_column
      line = 1
      line_start = 0
      idx = 0

      while idx < @position
        if @source[idx] == "\n"
          line += 1
          line_start = idx + 1
        end
        idx += 1
      end

      [line, @position - line_start + 1]
    end

    # Builds the full user-facing error message.
    #
    # @param message [String]
    # @return [String]
    def build_message(message)
      snippet = current_line
      caret = "#{' ' * [@column - 1, 0].max}^"

      "#{message} at line #{@line}, column #{@column}\n#{snippet}\n#{caret}"
    end

    # Returns the source line that contains the parse failure.
    #
    # @return [String]
    def current_line
      @source.lines[@line - 1]&.chomp || ''
    end
  end
end
