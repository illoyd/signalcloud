class PriceSheet
  attr_reader :country, :base_conversation_price, :base_phone_number_price
  
  def initialize( country, base_conversation_price=0.0, base_phone_number_price=0.0 )
    @country                 = country.to_s.upcase.to_sym
    @base_conversation_price = BigDecimal.new base_conversation_price, 8
    @base_phone_number_price = BigDecimal.new base_phone_number_price, 8
  end
end
