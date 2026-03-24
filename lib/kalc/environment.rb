# Stores functions, variables, and formula evaluation state for one scope.
module Kalc
  # Represents a runtime scope with variables, functions, and cycle tracking.
  class Environment
    MISSING = Object.new.freeze

    attr_reader :functions, :variables

    # @param parent [Environment, nil]
    def initialize(parent = nil)
      @functions = {}
      @variables = {}
      @parent = parent
      @formula_stack = parent ? parent.formula_stack : []
      yield self if block_given?
    end

    # Registers a function in the current scope.
    #
    # @param name [String, Symbol]
    # @param value [Object]
    # @return [Object]
    def add_function(name, value)
      @functions[normalize(name)] = value
    end

    # Looks up a function in the current scope chain.
    #
    # @param name [String, Symbol]
    # @return [Object]
    def get_function(name)
      key = normalize(name)
      return @functions[key] if @functions.key?(key)
      return @parent.get_function(name) if @parent

      MISSING
    end

    # Registers a variable in the current scope.
    #
    # @param name [String, Symbol]
    # @param value [Object]
    # @return [Object]
    def add_variable(name, value)
      @variables[normalize(name)] = value
      value
    end

    # Looks up a variable in the current scope chain.
    #
    # @param name [String, Symbol]
    # @return [Object]
    def get_variable(name)
      key = normalize(name)
      return @variables[key] if @variables.key?(key)
      return @parent.get_variable(name) if @parent

      MISSING
    end

    # Evaluates a formula while detecting circular references.
    #
    # @param formula [Object]
    # @param name [String, nil]
    # @return [Object]
    def with_formula(formula, name = nil)
      if @formula_stack.include?(formula.object_id)
        detail = name ? " for #{normalize(name)}" : ''
        raise CircularReferenceError, "Circular reference detected#{detail}"
      end

      @formula_stack << formula.object_id
      yield
    ensure
      @formula_stack.pop if @formula_stack.last == formula.object_id
    end

    protected

    attr_reader :formula_stack

    private

    # Normalizes variable and function identifiers for storage.
    #
    # @param name [String, Symbol]
    # @return [String]
    def normalize(name)
      name.to_s.strip
    end
  end
end
