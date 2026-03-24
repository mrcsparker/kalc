require 'kalc/builtins'

# Evaluates AST nodes against a persistent runtime environment.
module Kalc
  # Runs AST nodes against a mutable environment.
  class Interpreter
    attr_reader :env

    # Creates a fresh runtime and installs the builtin function set.
    def initialize
      @env = Environment.new
      Builtins.install(@env)
    end

    # Loads the standard library into the current environment.
    #
    # @param grammar [Grammar]
    # @param _transform [Object]
    # @return [Object]
    def load_stdlib(grammar, _transform = nil)
      input = File.read(File.join(__dir__, 'stdlib.kalc'))
      run(grammar.parse(input))
    end

    # Evaluates an AST in the current environment.
    #
    # @param ast [Object]
    # @return [Object]
    def run(ast)
      ast.eval(@env)
    end
  end
end
