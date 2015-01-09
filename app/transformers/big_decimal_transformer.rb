class BigDecimalTransformer

  def self.call(value)
    BigDecimal.new(value) rescue value
  end

end
