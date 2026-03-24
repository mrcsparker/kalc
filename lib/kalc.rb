require 'logger'

require 'kalc/version'
require 'kalc/grammar'
require 'kalc/ast'
require 'kalc/transform'
require 'kalc/environment'
require 'kalc/interpreter'
require 'bigdecimal'

# Top-level namespace for the Kalc language runtime.
module Kalc
  # Describes the accepted argument counts for a callable object.
  class FunctionArity
    # Builds an arity descriptor from Ruby block or method parameters.
    #
    # @param parameters [Array<Array<Symbol, Symbol>>]
    # @param leading [Integer] parameters to ignore at the start of the list
    # @return [FunctionArity]
    def self.from_parameters(parameters, leading: 0)
      parameter_kinds = parameters.drop(leading).map(&:first)

      new(
        required: parameter_kinds.count(:req),
        optional: parameter_kinds.count(:opt),
        variadic: parameter_kinds.include?(:rest)
      )
    end

    attr_reader :required, :optional

    # @param required [Integer]
    # @param optional [Integer]
    # @param variadic [Boolean]
    def initialize(required:, optional: 0, variadic: false)
      @required = required
      @optional = optional
      @variadic = variadic
    end

    # Returns whether the arity accepts the given argument count.
    #
    # @param argument_count [Integer]
    # @return [Boolean]
    def accepts?(argument_count)
      return false if argument_count < @required
      return true if @variadic

      argument_count <= @required + @optional
    end

    # Formats a readable error message for the accepted parameter counts.
    #
    # @return [String]
    def expected_message
      if @variadic
        "It needs at least #{@required} parameters"
      elsif @optional.zero?
        "It needs #{@required} parameters"
      else
        "It needs between #{@required} and #{@required + @optional} parameters"
      end
    end
  end

  # Raised when a lazily evaluated formula references itself.
  class CircularReferenceError < StandardError
  end

  autoload :Repl, 'kalc/repl'

  # Coordinates parsing and interpretation for one Kalc session.
  class Runner
    attr_accessor :grammar, :interpreter, :ast

    # @param debug [Boolean] enables parser and runtime logging
    def initialize(debug = false)
      @debug = debug
      @log = Logger.new($stdout)
      load_environment
    end

    # Rebuilds the parser and interpreter from scratch.
    #
    # @return [void]
    def reload
      load_environment
    end

    # Parses and evaluates a Kalc expression or program.
    #
    # @param expression [String]
    # @return [Object]
    def run(expression)
      @log.debug "Evaluating #{expression}" if @debug
      @ast = @debug ? @grammar.parse_with_debug(expression) : @grammar.parse(expression)
      @interpreter.run(ast)
    end

    private

    # Creates a fresh grammar and interpreter and loads the stdlib.
    #
    # @return [void]
    def load_environment
      @log.debug 'Loading grammar' if @debug
      @grammar = Kalc::Grammar.new
      @log.debug 'Loading interpreter' if @debug
      @interpreter = Kalc::Interpreter.new
      @log.debug 'Loading stdlib' if @debug
      @interpreter.load_stdlib(@grammar)
    end
  end
end
