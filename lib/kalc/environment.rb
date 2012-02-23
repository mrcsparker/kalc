module Kalc
  class Environment
    def initialize
      @functions = {}
      @variables = {}

      yield self if block_given?
    end

    def add_function(name, value)
      @functions.update({ name.to_s => value })
    end

    def get_function(name)
      @functions[name.to_s]
    end

    def add_variable(name, value)
      @variables.update({ name.to_s => value })
    end

    def get_variable(name)
      @variables[name.to_s]
    end

  end
end
