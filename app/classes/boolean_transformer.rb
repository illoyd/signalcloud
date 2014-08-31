class BooleanTransformer
  def self.call(value)
    return true  if value == true  ||                 value =~ (/\A(true|t|yes|y|1|on)\Z/i)
    return false if value == false || value.blank? || value =~ (/\A(false|f|no|n|0|off)\Z/i)
    raise ArgumentError.new("Invalid value for boolean: \"#{value}\"")
  end
end
