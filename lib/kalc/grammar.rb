require 'kalc/grammar/parse_error'
require 'kalc/grammar/lexer'
require 'kalc/grammar/parser'

# Entry point for tokenizing and parsing Kalc source.
module Kalc
  # Converts source text into AST programs.
  class Grammar
    # Lightweight token object emitted by the lexer.
    Token = Struct.new(:type, :value, :position, keyword_init: true)

    # Parses source text into an AST.
    #
    # @param source [String]
    # @return [Ast::Program]
    def parse(source)
      tokens = Lexer.new(source).tokenize
      Parser.new(tokens, source).parse
    end

    # Parses source text while preserving the public debug entry point.
    #
    # @param source [String]
    # @return [Ast::Program]
    def parse_with_debug(source)
      parse(source)
    end
  end
end
