class BlankToNilTransformer

  def self.call(value)
    value.blank? ? nil : value
  end

end
