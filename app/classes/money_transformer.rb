class MoneyTransformer < BigDecimalTransformer

  def self.call(value)
    value = value.to_s.gsub(/([^\d,.]+)/, '')
    super(value)
  end

end
