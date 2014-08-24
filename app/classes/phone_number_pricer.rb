class PhoneNumberPricer < Pricer
  
  def price_for(phone_number)
    return 0 unless phone_number.active?
    country = PhoneTools.country( phone_number.number )
    price_for_country(country)
  end
  
  def price_for_country(country)
    pricesheet = self.price_sheet_for(country)
    pricesheet.base_phone_number_price
  end

end