class PhoneNumberPricer < Pricer
  
  def price_for( phone_number )
    country = PhoneTools.country( phone_number.number )
    pricesheet = self.price_sheet_for( country )
    pricesheet.base_phone_number_price
  end

end