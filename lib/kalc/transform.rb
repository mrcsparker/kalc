# Compatibility layer for legacy transform-based entry points.
module Kalc
  # Compatibility shim for older entry points that still instantiate a transform.
  class Transform
    # Returns the AST unchanged.
    #
    # @param node [Object]
    # @return [Object]
    def apply(node)
      node
    end
  end
end
