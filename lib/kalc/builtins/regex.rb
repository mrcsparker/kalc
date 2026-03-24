# Regular-expression-oriented builtin functions.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Regex helpers for matching and replacement.
    module Regex
      module_function

      # Registers the regex builtins.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_eager(env, :REGEXP_MATCH) do |value, pattern|
          Regexp.new(pattern).match(value)
        end

        Helpers.define_eager(env, :REGEXP_REPLACE) do |value, pattern, replacement|
          value.gsub(Regexp.new(pattern), replacement)
        end
      end
    end
  end
end
