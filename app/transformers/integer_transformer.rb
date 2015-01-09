class IntegerTransformer

  def self.call(value)
    Integer(value) rescue value
  end

end
