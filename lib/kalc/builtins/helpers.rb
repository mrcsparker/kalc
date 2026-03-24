# Shared helpers for registering and working with builtin functions.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Utilities shared across builtin modules.
    module Helpers
      # Wraps a Ruby block so it behaves like a callable Kalc function.
      class Callable
        attr_reader :arity

        # @param eager [Boolean] whether to eagerly evaluate arguments
        # @param implementation [Proc]
        def initialize(eager:, implementation:)
          @eager = eager
          @implementation = implementation
          @arity = FunctionArity.from_parameters(implementation.parameters, leading: eager ? 0 : 1)
        end

        # Invokes the builtin against the current execution context.
        #
        # @param context [Environment]
        # @param arguments [Array<Object>]
        # @return [Object]
        def call(context, *arguments)
          if @eager
            @implementation.call(*arguments.map { |argument| argument.eval(context) })
          else
            @implementation.call(context, *arguments)
          end
        end
      end

      module_function

      # Registers a builtin whose arguments should be evaluated before dispatch.
      #
      # @param env [Environment]
      # @param name [String, Symbol]
      # @return [void]
      def define_eager(env, name, &implementation)
        env.add_function(name, Callable.new(eager: true, implementation: implementation))
      end

      # Registers a builtin that receives unevaluated AST nodes and the context.
      #
      # @param env [Environment]
      # @param name [String, Symbol]
      # @return [void]
      def define_lazy(env, name, &implementation)
        env.add_function(name, Callable.new(eager: false, implementation: implementation))
      end

      # Returns whether the value is a non-finite {BigDecimal}.
      #
      # @param value [Object]
      # @return [Boolean]
      def special_numeric?(value)
        value.is_a?(BigDecimal) && (value.nan? || value.infinite?)
      end

      # Returns whether the value is an array literal result.
      #
      # @param value [Object]
      # @return [Boolean]
      def array_value?(value)
        value.is_a?(Ast::ArrayValue)
      end

      # Flattens scalars and nested array values into one scalar list.
      #
      # @param values [Array<Object>]
      # @return [Array<Object>]
      def scalar_values(values)
        values.flat_map do |value|
          next scalar_values(value.flat_values) if array_value?(value)

          [value]
        end
      end

      # Ensures a value is an {Ast::ArrayValue}.
      #
      # @param value [Object]
      # @param function_name [String, Symbol]
      # @return [Ast::ArrayValue]
      def expect_array!(value, function_name)
        return value if array_value?(value)

        raise ArgumentError, "#{function_name} expects an array value"
      end
    end
  end
end
