# Core control-flow and predicate builtins.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Lazy control-flow and predicate functions.
    module Core
      module_function

      # Registers the core builtin functions.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_lazy(env, :IF) do |context, condition, if_true, if_false|
          condition.eval(context) ? if_true.eval(context) : if_false.eval(context)
        end

        Helpers.define_lazy(env, :OR) do |context, *arguments|
          arguments.any? { |argument| argument.eval(context) }
        end

        Helpers.define_lazy(env, :NOT) do |context, value|
          !value.eval(context)
        end

        Helpers.define_lazy(env, :AND) do |context, *arguments|
          arguments.all? { |argument| argument.eval(context) }
        end

        Helpers.define_lazy(env, :IFS) do |context, *arguments|
          evaluate_ifs(context, arguments)
        end

        Helpers.define_lazy(env, :SWITCH) do |context, expression, *arguments|
          evaluate_switch(context, expression, arguments)
        end

        Helpers.define_lazy(env, :CHOOSE) do |context, index, *choices|
          choose_value(context, index, choices)
        end

        Helpers.define_eager(env, :RAND) { |value| rand(value) }

        Helpers.define_lazy(env, :SYSTEM) do |_context, *_arguments|
          raise SecurityError, 'SYSTEM is disabled'
        end

        Helpers.define_eager(env, :ISLOGICAL) { |value| [true, false].include?(value) }
        Helpers.define_eager(env, :ISNONTEXT) { |value| !value.is_a?(String) }
        Helpers.define_eager(env, :ISNUMBER) { |value| value.is_a?(Numeric) }
        Helpers.define_eager(env, :ISTEXT) { |value| value.is_a?(String) }
      end

      # Evaluates Excel-style condition/result pairs.
      #
      # @param context [Environment]
      # @param arguments [Array<Object>]
      # @return [Object]
      def evaluate_ifs(context, arguments)
        raise ArgumentError, 'IFS expects condition/result pairs' if arguments.empty? || arguments.length.odd?

        arguments.each_slice(2) do |condition, result|
          return result.eval(context) if condition.eval(context)
        end

        raise ArgumentError, 'IFS did not match any condition'
      end

      # Evaluates a SWITCH expression and optional default branch.
      #
      # @param context [Environment]
      # @param expression [Object]
      # @param arguments [Array<Object>]
      # @return [Object]
      def evaluate_switch(context, expression, arguments)
        raise ArgumentError, 'SWITCH expects at least one value/result pair' if arguments.length < 2

        expression_value = expression.eval(context)
        default = arguments.length.odd? ? arguments.last : nil
        pairs = default ? arguments[0...-1] : arguments

        pairs.each_slice(2) do |candidate, result|
          return result.eval(context) if expression_value == candidate.eval(context)
        end

        return default.eval(context) if default

        raise ArgumentError, 'SWITCH did not match any value'
      end

      # Selects one item from the provided choice list.
      #
      # @param context [Environment]
      # @param index [Object]
      # @param choices [Array<Object>]
      # @return [Object]
      def choose_value(context, index, choices)
        raise ArgumentError, 'CHOOSE expects at least one choice' if choices.empty?

        choice = choices.fetch(Integer(index.eval(context)) - 1) do
          raise ArgumentError, 'CHOOSE index is out of range'
        end

        choice.eval(context)
      end
    end
  end
end
