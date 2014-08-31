class MakeTwilioConversationTieredPricesheetJob < ActiveJob::Base
  queue_as :default

  def perform(multiple_of = 0.10, min_margin = 0.01)
    # Download Twilio's phone number pricesheet
    pricesheet = Twilio::SmsPricesheet.parse
    
    # For every entry, make it a multiple
    Hash[ pricesheet.map { |k,v| [k, round(v, multiple_of, min_margin)] } ]
  end
  
  def round(value, multiple_of, min_margin)
    ( (value.to_f + min_margin) / multiple_of ).ceil * multiple_of
  end

end