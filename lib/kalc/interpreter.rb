# Code inspired by https://github.com/txus/schemer

module Kalc
  class Interpreter

    attr_reader :env

    def initialize(ast = nil)

      @ast = ast

      @env = Environment.new do |env|

        env.add_function(:IF, lambda { |cxt, *args|
          args[0].eval(cxt) ? args[1].eval(cxt) : args[2].eval(cxt)
        })

        env.add_function(:OR, lambda { |cxt, *args|
          args = to_array(args)
          retval = false
          args.each do |arg|
            if arg.eval(cxt) == true
              retval = true
              break
            end
          end
          retval
        })

        env.add_function(:AND, lambda { |cxt, *args|
          args = to_array(args)
          retval = true
          args.each do |arg|
            if arg.eval(cxt) == false
              retval = false
              break
            end
          end
          retval
        })

        # Math
        env.add_function(:COS, lambda { |cxt, *args|
          args = to_array(args)
          Math.cos(args.first.eval(cxt))
        })
      end
    end

    def run(ast = nil)
      @ast = ast if ast
      @ast.eval(@env)
    end

    private
    def to_array(*arr)
      arr = [arr] unless arr.is_a?(Array)
      arr
    end
  end
end
