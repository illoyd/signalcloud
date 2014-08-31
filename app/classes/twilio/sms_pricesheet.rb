require 'open-uri'

module Twilio
  class SmsPricesheet
  
    DEFAULT_URI = 'http://www.twilio.com/resources/rates/international-sms-rates.csv'
  
    def self.parse
      self.new.parse(DEFAULT_URI)
    end
    
    attr_accessor :prices
  
    def initialize
      @prices = HashWithIndifferentAccess.new { |hash,key| hash[key] = BigDecimal.new 0 }
    end

    def parse(file)
      CSV.new(open(file), headers: :first_row).each do |line|
        parse_provider(MobileProvider.new(line.to_hash))
      end
      @prices
    end
    
    def parse_provider(provider)
      # Skip if country is blank
      return unless provider.alpha2.present? && provider.cost.present?
      
      # Add price if new or if greater than past price
      prior_cost = @prices[provider.alpha2]
      @prices[provider.alpha2] = [prior_cost, provider.cost].max
    end
    
    class MobileProvider < ::APISmith::Smash
      property :alpha2, from: :Country
      property :cost,   from: ' Rate',  transformer: MoneyTransformer
    end
  end
end