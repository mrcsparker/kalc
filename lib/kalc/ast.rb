module Kalc
  module Ast
    class Commands
      attr_reader :commands

      def initialize(commands)
        @commands = commands
      end

      def eval(context)
        last = nil
        @commands.each do |command|
          last = command.eval(context)
        end
        last
      end
    end

    class Expressions
      attr_reader :expressions

      def initialize(expressions)
        @expressions = expressions
      end

      def eval(context)
        last = nil
        @expressions.each do |exp|
          last = exp.eval(context)
        end
        last
      end
    end

    class Negative
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        begin
          -(@value.eval(context))
        rescue
          @value.eval(context)
        end
      end
    end

    # Does nothing.  For compat.
    class Positive
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        begin
          +(@value.eval(context))
        rescue
          @value.eval(context)
        end
      end
    end

    class BooleanValue
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        @value == 'TRUE' ? true : false
      end
    end

    class BigDecimalNumber
      attr_reader :value

      def initialize(value)
        @value = BigDecimal.new(value.to_s)
      end

      def eval(context)
        BigDecimal.new(@value)
      end
    end

    class ParenExpression
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        @value.eval(context)
      end
    end

    class NonOps
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        Arithmetic.new(@value.left.eval(context), @value.right.eval(context), @value.operator).eval(context)
      end
    end

    class Ops
      attr_reader :left
      attr_reader :ops

      def initialize(left, ops)
        @left = left
        @ops = ops
      end

      def eval(context)
        @ops.inject(@left.eval(context)) { |x, op|
          a = Arithmetic.new(x, op[:right].eval(context), op[:operator])
          a.eval(context)
        }
      end
    end

    class Arithmetic
      attr_reader :left
      attr_reader :right
      attr_reader :operator

      def initialize(left, right, operator)
        @left = left
        @right = right
        @operator = operator
      end

      def eval(context)
        case @operator.to_s.strip
        when '&&'
          @left && @right
        when 'and'
          @left && @right
        when '||'
          @left || @right
        when 'or'
          @left || @right
        when '<='
          @left <= @right
        when '>='
          @left >= @right
        when '='
          @left == @right
        when '=='
          @left == @right
        when '!='
          @left != @right
        when '-'
          @left - @right
        when '+'
          @left + @right
        when '^'
          @left**@right
        when '*'
          @left * @right
        when '/'
          @left / @right
        when '%'
          @left % @right
        when '<'
          @left < @right
        when '>'
          @left > @right
        end
      end
    end

    class Conditional
      attr_reader :condition, :true_cond, :false_cond

      def initialize(condition, true_cond, false_cond)
        @condition = condition
        @true_cond = true_cond
        @false_cond = false_cond
      end

      def eval(context)
        @condition.eval(context) ? @true_cond.eval(context) : @false_cond.eval(context)
      end
    end

    class Identifier
      attr_reader :identifier
      attr_reader :value

      def initialize(identifier, value)
        @variable = identifier.to_s.strip
        @value = value
      end

      def eval(context)
        context.add_variable(@variable, @value.eval(context))
      end
    end

    class Variable
      attr_reader :variable

      def initialize(variable)
        @variable = variable
      end

      def eval(context)
        context.get_variable(@variable)
      end
    end

    class StringValue
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def eval(context)
        value.to_s
      end
    end

    class FunctionCall
      attr_reader :name
      attr_reader :variable_list

      def initialize(name, variable_list)
        @name = name
        @variable_list = variable_list
      end

      def eval(context)
        to_call = context.get_function(@name)
        to_call.call(context, *@variable_list) if to_call
      end
    end

    class FunctionDefinition
      def initialize(name, argument_list, body)
        @name = name
        @argument_list = argument_list
        @body = body
      end

      def eval(context)
        context.add_function(@name.to_sym, lambda { |parent_context, *args|
          dup_body = Marshal.load(Marshal.dump(@body))
          cxt = Environment.new(parent_context)
          args.each_with_index do |arg, idx|
            cxt.add_variable(@argument_list[idx].value, arg.eval(cxt))
          end
          dup_body.eval(cxt)
        })
        nil
      end
    end
  end
end
