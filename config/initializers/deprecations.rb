module Deprecations
 
  # Define a deprecated alias for a method
  # @param [Symbol] name - name of method to define
  # @param [Symbol] replacement - name of method to (alias)
  def deprecated_alias(name, replacement)
    # Create a wrapped version
    define_method(name) do |*args, &block|
      warn "SignalCloud: ##{name} deprecated (please use ##{replacement})"
      send replacement, *args, &block
    end
  end
 
  # Deprecate a defined method
  # @param [Symbol] name - name of deprecated method
  # @param [Symbol] replacement - name of the desired replacement
  def deprecated(name, replacement = nil)
    # Replace old method
    old_name = :"#{name}_without_deprecation"
    alias_method old_name, name
    # And replace it with a wrapped version
    define_method(name) do |*args, &block|
      if replacement
        warn "SignalCloud: ##{name} deprecated (please use ##{replacement})"
      else
        warn "SignalCloud: ##{name} deprecated"
      end
      send old_name, *args, &block
    end
  end
 
end