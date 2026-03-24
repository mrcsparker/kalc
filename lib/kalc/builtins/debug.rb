require 'pp'

# Debugging and inspection builtins.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Helper functions for inspecting values while developing formulas.
    module Debug
      module_function

      # Registers the debugging builtins.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_eager(env, :P) do |*values|
          p(values)
        end

        Helpers.define_eager(env, :PP) do |*values|
          pp(values)
        end

        Helpers.define_lazy(env, :PUTS) do |context, output|
          puts output.eval(context)
        end
      end
    end
  end
end
