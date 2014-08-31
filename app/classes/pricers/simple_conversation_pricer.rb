module Pricers
  class SimpleConversationPricer < Pricer
  
    def price_for(object)
      base_price  = base_price_for(object)
      extra_price = extra_price_for(object, base_price)
      base_price + extra_price
    end
    
  protected

    ##
    # Return the expected price for the given country
    def base_price_for(object)
      case object
      when Conversation
        object.draft? ? BigDecimal.new(0) : base_price_for(object.customer_number)

      when PhoneNumber
        base_price_for(object.number.country.alpha2)

      when MiniPhoneNumber
        base_price_for(object.country.alpha2)

      when Country
        base_price_for(object.alpha2)

      else
        return base_price_for(MiniPhoneNumber.new(object)) if Country.plausible_phone_number?(object)
      
        raise SignalCloud::UnpriceableObjectError, object unless prices.include?(object)

        BigDecimal.new prices[object], 8
      end
    end
    
    ##
    # Return the extra price, if appropriate, for the given object.
    # If the base price is not already provided, look it up
    def extra_price_for(object, base_price = nil)
      base_price ||= base_price_for(object)

      case object
      when Conversation
        base_price.div(2, 8) * [0, object.messages.outbound.sum(:segments) - 2].max

      else
        BigDecimal.new 0
      end
    end
    
  end
end