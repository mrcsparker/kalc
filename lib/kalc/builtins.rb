require 'kalc/builtins/helpers'
require 'kalc/builtins/arrays'
require 'kalc/builtins/core'
require 'kalc/builtins/math'
require 'kalc/builtins/strings'
require 'kalc/builtins/regex'
require 'kalc/builtins/debug'

# Installs the standard builtin namespaces into an environment.
module Kalc
  # Namespace for grouped builtin function installers.
  module Builtins
    module_function

    # Registers every builtin module with the provided environment.
    #
    # @param env [Environment]
    # @return [void]
    def install(env)
      Arrays.install(env)
      Core.install(env)
      Math.install(env)
      Strings.install(env)
      Regex.install(env)
      Debug.install(env)
    end
  end
end
