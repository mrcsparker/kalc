module Kalc
  class Environment

    attr_reader :functions
    attr_reader :variables

    def initialize
      @functions = {}
      @variables = {}
      yield self if block_given?
    end

    def add_function(name, value)
      @functions.update({ name.to_s.strip => value })
    end

    def get_function(name)
      @functions[name.to_s.strip]
    end

    def list_functions
      @functions
    end

    def add_variable(name, value)
      @variables.update({ name.to_s.strip => value })
    end

    def get_variable(name)
      @variables[name.to_s.strip]
    end

  end
end
