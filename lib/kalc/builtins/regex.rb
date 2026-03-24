# Regular-expression-oriented builtin functions.
module Kalc
  # Namespace for grouped builtin installers.
  module Builtins
    # Regex helpers for matching and replacement.
    module Regex
      module_function

      REGEXP_TIMEOUT_SECONDS = 0.1

      # Registers the regex builtins.
      #
      # @param env [Environment]
      # @return [void]
      def install(env)
        Helpers.define_eager(env, :REGEXP_MATCH) do |value, pattern|
          with_safe_regexp(pattern) { |regexp| regexp.match(value) }
        end

        Helpers.define_eager(env, :REGEXP_REPLACE) do |value, pattern, replacement|
          with_safe_regexp(pattern) { |regexp| value.gsub(regexp, replacement) }
        end
      end

      # Returns the timeout used for user-supplied regular expressions.
      #
      # @return [Numeric]
      def regexp_timeout
        REGEXP_TIMEOUT_SECONDS
      end

      # Compiles and executes a user-supplied regular expression with a timeout.
      #
      # @param pattern [String, Regexp]
      # @yieldparam regexp [Regexp]
      # @return [Object]
      def with_safe_regexp(pattern)
        yield Regexp.new(pattern, timeout: regexp_timeout)
      rescue Regexp::TimeoutError
        raise ArgumentError, 'Regular expression exceeded the time limit'
      end
    end
  end
end
