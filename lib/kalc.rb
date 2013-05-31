require 'parslet'
require 'logger'

require 'kalc/version'
require 'kalc/grammar'
require 'kalc/ast'
require 'kalc/transform'
require 'kalc/environment'
require 'kalc/interpreter'
require 'kalc/repl'

module Kalc
  class Runner

    attr_accessor :grammar
    attr_accessor :transform
    attr_accessor :interpreter
    attr_accessor :ast

    def initialize(debug = false)
      @debug = debug
      @log = Logger.new(STDOUT)
      load_environment
    end

    def reload
      load_environment
    end

    def run(expression)
      if @debug
        @log.debug "Evaluating #{expression}"
        g = @grammar.parse_with_debug(expression)
      else
        g = @grammar.parse(expression)
      end
      @ast = @transform.apply(g)
      @interpreter.run(ast)
    end

    private
    def load_environment
      @log.debug 'Loading grammar' if @debug
      @grammar = Kalc::Grammar.new
      @log.debug 'Loading transform' if @debug
      @transform = Kalc::Transform.new
      @log.debug 'Loading interpreter' if @debug
      @interpreter = Kalc::Interpreter.new
      @log.debug 'Loading stdlib' if @debug
      @interpreter.load_stdlib(@grammar, @transform)
    end
  end
end

