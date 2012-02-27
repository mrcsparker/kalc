# Code inspired by https://github.com/txus/schemer

require 'pp'

module Kalc
  class Interpreter

    attr_reader :env

    def initialize
      @env = Environment.new do |env|

        env.add_function(:IF, lambda { |cxt, cond, if_true, if_false|
          cond.eval(cxt) ? if_true.eval(cxt) : if_false.eval(cxt)
        })

        env.add_function(:OR, lambda { |cxt, *args|
          retval = false
          args.each do |arg|
            if arg.eval(cxt) == true
              retval = true
              break
            end
          end
          retval
        })

        env.add_function(:NOT, lambda { |cxt, val|  
          !val.eval(cxt)
        })

        env.add_function(:AND, lambda { |cxt, *args|
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
        env.add_function(:ABS, lambda { |cxt, val|
          val.eval(cxt).abs
        })

        env.add_function(:DEGREES, lambda { | cxt, val|  
          val.eval(cxt) * (180.0 / Math::PI)
        })

        env.add_function(:PRODUCT, lambda { |cxt, *args|  
          args.map { |a| a.eval(cxt) }.inject(:*)
        })

        env.add_function(:RADIANS, lambda { |cxt, val|  
          val.eval(cxt) * (Math::PI / 180.0)
        })

        env.add_function(:ROUND, lambda { |cxt, num, digits|  
          num.eval(cxt).round(digits.eval(cxt))
        })

        env.add_function(:SUM, lambda { |cxt, *args|  
          args.map { |a| a.eval(cxt) }.inject(:+)
        })

        env.add_function(:TRUNC, lambda { |cxt, val|  
          Integer(val.eval(cxt))
        })

        math_funs = 
          [ 'acos', 'acosh', 'asin', 'asinh', 'atan', 'atanh',
            'cbrt', 'cos', 'cosh',
            'erf', 'erfc', 'exp',
            'log', 'log2', 'log10',
            'sin', 'sinh', 'sqrt',
            'tan', 'tanh',
             ]

        math_funs.each do |math_fun|
          env.add_function(math_fun.upcase.to_sym, lambda { |cxt, val|
            Math.send(math_fun.to_sym, val.eval(cxt))
          })
        end

        env.add_function(:P, lambda { |cxt, *output|  
          p output
        })

        env.add_function(:PP, lambda { |cxt, *output|  
          pp output
        })

      end
    end

    def run(ast)
      ast.eval(@env)
    end
  end
end
