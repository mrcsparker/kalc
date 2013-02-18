# Code inspired by https://github.com/txus/schemer

require 'pp'

module Kalc
  class Interpreter

    attr_accessor :env

    def initialize
      @env = Environment.new do |env|

        env.add_function(:IF, lambda { |cxt, cond, if_true, if_false|
          cond.eval(cxt) ? if_true.eval(cxt) : if_false.eval(cxt)
        })

        env.add_function(:OR, lambda { |cxt, *args|
          retval = false
          args.each do |arg|
            if arg.eval(cxt)
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
            unless arg.eval(cxt)
              retval = false
              break
            end
          end
          retval
        })

        env.add_function(:RAND, lambda { |cxt, val|
          rand(val.eval(cxt))
        })

        env.add_function(:SYSTEM, lambda { |cxt, val|
          throw "Nope.  I don't think so!"
        })

        # IS?
        env.add_function(:ISLOGICAL, lambda { |cxt, val|
          newval = val.eval(cxt)
          newval == true || newval == false
        })

        env.add_function(:ISNONTEXT, lambda { |cxt, val|
          !val.eval(cxt).is_a? String
        })

        env.add_function(:ISNUMBER, lambda { |cxt, val|
          val.eval(cxt).is_a? Numeric
        })

        env.add_function(:ISTEXT, lambda { |cxt, val|
          val.eval(cxt).is_a? String
        })

        # Math
        env.add_function(:ABS, lambda { |cxt, val|
          val.eval(cxt).abs
        })

        env.add_function(:DEGREES, lambda { |cxt, val|
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

        env.add_function(:LN, lambda { |cxt, val|
          Math.log(val.eval(cxt))
        })

        math_funs =
            %w(acos acosh asin asinh atan atanh cbrt cos cosh erf erfc exp gamma lgamma log log2 log10 sin sinh sqrt tan tanh)

        math_funs.each do |math_fun|
          env.add_function(math_fun.upcase.to_sym, lambda { |cxt, val|
            Math.send(math_fun.to_sym, val.eval(cxt))
          })
        end

        # Strings
        string_funs =
            %w(chomp chop chr clear count
            downcase
            hex
            inspect intern
            to_sym length size lstrip succ next oct ord reverse rstrip strip swapcase to_c to_f to_i to_r upcase)

        string_funs.each do |str_fun|
          env.add_function(str_fun.upcase.to_sym, lambda { |cxt, val|
            String.new(val.eval(cxt)).send(str_fun.to_sym)
          })
        end

        env.add_function(:CHAR, lambda { |cxt, val|
          Integer(val.eval(cxt)).chr
        })

        env.add_function(:CLEAN, lambda { |cxt, val|
          val.eval(cxt).gsub(/\P{ASCII}/, '')
        })

        env.add_function(:CODE, lambda { |cxt, val|
          val.eval(cxt).ord
        })

        env.add_function(:CONCATENATE, lambda { |cxt, *args|
          args.map { |a| a.eval(cxt) }.join
        })

        env.add_function(:DOLLAR, lambda { |cxt, val, decimal_places|
          "%.#{Integer(decimal_places.eval(cxt))}f" % Float(val.eval(cxt))
        })

        env.add_function(:EXACT, lambda { |cxt, string1, string2|
          string1.eval(cxt) == string2.eval(cxt)
        })

        env.add_function(:FIND, lambda { |cxt, string1, string2, starting_pos|
          start = Integer(starting_pos.eval(cxt)) - 1
          string1.eval(cxt)[start..-1].index(string2.eval(cxt)) + 1
        })

        env.add_function(:FIXED, lambda { |cxt, val, decimal_places, no_commas|
          output = "%.#{Integer(decimal_places.eval(cxt))}f" % Float(val.eval(cxt))
          output = output.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse if !no_commas.eval(cxt)
          output
        })

        env.add_function(:LEFT, lambda { |cxt, val, number_of_characters|
          num = Integer(number_of_characters.eval(cxt)) - 1
          val.eval(cxt)[0..num]
        })

        env.add_function(:LEN, lambda { |cxt, val|
          val.eval(cxt).length
        })

        env.add_function(:LOWER, lambda { |cxt, val|
          val.eval(cxt).downcase
        })

        env.add_function(:MID, lambda { |cxt, val, start_position, number_of_characters|

          start = Integer(start_position.eval(cxt)) - 1
          chars = Integer(number_of_characters.eval(cxt)) - 1

          val.eval(cxt)[start..chars + start]
        })

        env.add_function(:PROPER, lambda { |cxt, val|
          val.eval(cxt).split(" ").map { |c| c.capitalize }.join(" ")
        })

        env.add_function(:REPLACE, lambda { |cxt, val, start_position, number_of_chars, new_text|
          start = Integer(start_position.eval(cxt)) - 1
          chars = Integer(number_of_chars.eval(cxt)) - 1
          output = val.eval(cxt)
          output[start..chars + start] = new_text.eval(cxt)
          output
        })

        env.add_function(:REPT, lambda { |cxt, val, number_of_times|
          val.eval(cxt) * Integer(number_of_times.eval(cxt))
        })

        env.add_function(:RIGHT, lambda { |cxt, val, number_of_characters|
          num = -Integer(number_of_characters.eval(cxt))
          val.eval(cxt)[num..-1]
        })

        env.add_function(:SEARCH, lambda { |cxt, string1, string2, start_position|
          start = Integer(start_position.eval(cxt)) - 1
          string2.eval(cxt).downcase[start..-1].index(string1.eval(cxt).downcase) + 1
        })

        env.add_function(:SUBSTITUTE, lambda { |cxt, val, old_text, new_text|
          val.eval(cxt).gsub(old_text.eval(cxt), new_text.eval(cxt))
        })

        env.add_function(:TRIM, lambda { |cxt, val|
          val.eval(cxt).strip
        })

        env.add_function(:UPPER, lambda { |cxt, val|
          val.eval(cxt).upcase
        })

        env.add_function(:VALUE, lambda { |cxt, val|
          val.eval(cxt).to_f
        })

        # Regular expressions

        env.add_function(:REGEXP_MATCH, lambda { |cxt, val, regex|
          r = regex.eval(cxt)
          /#{r}/.match(val.eval(cxt))
        })

        env.add_function(:REGEXP_REPLACE, lambda { |cxt, val, regex, to_replace|
          r = regex.eval(cxt)

          val.eval(cxt).gsub(/#{r}/, to_replace.eval(cxt))
        })

        # Debug
        env.add_function(:P, lambda { |cxt, *output|
          p output
        })

        env.add_function(:PP, lambda { |cxt, *output|
          pp output
        })

        env.add_function(:PUTS, lambda { |cxt, output|
          puts output.eval(cxt)
        })

      end
    end

    def load_stdlib(grammar, transform)
      stdlib = "#{File.dirname(__FILE__)}/stdlib.kalc"
      input = File.read(stdlib)
      g = grammar.parse(input)
      ast = transform.apply(g)
      run(ast)
    end

    def run(ast)
      ast.eval(@env)
    end
  end
end
