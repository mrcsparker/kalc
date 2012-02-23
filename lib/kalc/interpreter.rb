# Code inspired by https://github.com/txus/schemer

module Kalc
  class Interpreter
    def initialize(ast = nil)

      @ast = ast

      @env = Environment.new do |env|
        env.add_function(:IF, lambda do |cxt, *args|
          args[0].eval(cxt) ? args[1].eval(cxt) : args[2].eval(cxt)
        end)

        env.add_function(:OR, lambda do |cxt, *args|
          retval = false
          args.each do |arg|
            if arg.eval(cxt) == true
              retval = true
              break
            end
          end
          retval
        end)

        env.add_function(:AND, lambda do |cxt, *args|
          args.all?
        end)

      end
    end

    def run
      @ast.eval(@env)
    end

  end
end
