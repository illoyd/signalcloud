require 'open-uri'

module Twilio
  class PhoneNumberPricesheet
  
    DEFAULT_URI = 'http://www.twilio.com/resources/rates/international-phone-number-rates.csv'
  
    def self.parse
      self.new.parse(DEFAULT_URI)
    end
    
    attr_accessor :prices
  
    def initialize
      @prices = HashWithIndifferentAccess.new { |hash,key| hash[key] = BigDecimal.new 0 }
    end

    def parse(file)
      CSV.new(open(file), headers: :first_row).each do |line|
        phone_number = PhoneNumber.new(line.to_hash)
        parse_phone_number(phone_number)
      end
      @prices
    end
    
    def parse_phone_number(phone_number)
      # Skip if not an SMS enabled phone
      return unless phone_number.sms?
      
      # Add price if new or if greater than past price
      prior_price = @prices[phone_number.alpha2]
      @prices[phone_number.alpha2] = [prior_price, phone_number.cost].max
    end
    
    class PhoneNumber < ::APISmith::Smash
      property :alpha2, required: true, from: :ISO
      property :sms?,   required: true, from: 'SMS Enabled',      transformer: BooleanTransformer
      property :cost,   required: true, from: 'Price /num/month', transformer: MoneyTransformer
    end
  end
end