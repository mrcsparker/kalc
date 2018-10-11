module Kalc
  class Environment
    attr_reader :functions
    attr_reader :variables

    def initialize(parent = nil)
      @functions = {}
      @variables = {}
      @parent = parent
      yield self if block_given?
    end

    def add_function(name, value)
      @functions.update(name.to_s.strip => value)
    end

    def get_function(name)
      if (fun = @functions[name.to_s.strip])
        fun
      elsif !@parent.nil?
        @parent.get_function(name)
      end
    end

    def add_variable(name, value)
      @variables.update(name.to_s.strip => value)
      value
    end

    def get_variable(name)
      if (var = @variables[name.to_s.strip])
        var
      elsif !@parent.nil?
        @parent.get_variable(name)
      end
    end
  end
end
