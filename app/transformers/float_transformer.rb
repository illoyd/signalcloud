class FloatTransformer

  def self.call(value)
    value.to_f rescue value
  end

end
