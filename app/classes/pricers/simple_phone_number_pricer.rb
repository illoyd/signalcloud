module Pricers
  class SimplePhoneNumberPricer < Pricer
  
    def price_for(object)
      base_price_for(object)
    end
    
  protected

    def base_price_for(object)
      case object
      when PhoneNumber
        base_price_for(object.number.country.alpha2)

      when MiniPhoneNumber
        base_price_for(object.country.alpha2)

      when Country
        base_price_for(object.alpha2)

      else
        return base_price_for(MiniPhoneNumber.new(object)) if Country.plausible_phone_number?(object)
      
        raise SignalCloud::UnpriceableObjectError, object unless prices.include?(object)

        BigDecimal.new prices[object] 
      end
    end
    
  end
end