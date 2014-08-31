class MakeTwilioPhoneNumberTieredPricesheetJob < ActiveJob::Base
  queue_as :default

  def perform(multiple_of = 3.0, min_margin = 1.0)
    # Download Twilio's phone number pricesheet
    pricesheet = Twilio::PhoneNumberPricesheet.parse
    
    # For every entry, make it a multiple
    Hash[ pricesheet.map { |k,v| [k, round(v, multiple_of, min_margin)] } ]
  end
  
  def round(value, multiple_of, min_margin)
    ( (value.to_f + min_margin) / multiple_of ).ceil * multiple_of
  end

end