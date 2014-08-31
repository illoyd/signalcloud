module Pricers
  class FreePricer < Pricer
    def price_for(object)
      BigDecimal.new 0
    end
  end
end