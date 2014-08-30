require 'open-uri'

module Twilio
  class PhoneNumberPricesheet
  
    def initialize
      @tiers = [
        Tier.new(    0..1,  BigDecimal.new( 2)),
        Tier.new( 1.01..3,  BigDecimal.new( 4)),
        Tier.new( 3.01..5,  BigDecimal.new( 6)),
        Tier.new( 5.01..7,  BigDecimal.new( 8)),
        Tier.new( 7.01..9,  BigDecimal.new(10)),
        Tier.new( 9.01..11, BigDecimal.new(12)),
        Tier.new(11.01..13, BigDecimal.new(14)),
        Tier.new(13.01..15, BigDecimal.new(16)),
        Tier.new(15.01..17, BigDecimal.new(18)),
        Tier.new(17.01..19, BigDecimal.new(20))
      ]
      @tiers = [
        Tier.new(    0..2,  BigDecimal.new(  3)),
        Tier.new( 2.01..5,  BigDecimal.new(  6)),
        Tier.new( 5.01..8,  BigDecimal.new(  9)),
        Tier.new( 8.01..11, BigDecimal.new( 12)),
        Tier.new(11.01..14, BigDecimal.new( 15)),
        Tier.new(14.01..99, BigDecimal.new(100))
      ]
      @prices = Hash.new { |hash,key| hash[key] = BigDecimal.new 0 }
    end
    
    def parse(file)
      CSV.new(open(file), headers: :first_row).each do |line|
        phone_number = PhoneNumber.new(line.to_hash)
        parse_phone_number(phone_number)
      end
      @prices
    end
    
    def parse_phone_number(phone_number)
      return unless phone_number.sms_enabled
      
      prior_price = prices[phone_number.iso]
      new_price   = lookup_price(phone_number.cost)
      prices[phone_number.iso] = [prior_price, new_price].max
    end
    
    def lookup_price(cost)
      tiers.each { |tier| return tier.price if tier.range.include?(cost) }
    end
    
    Tier = Struct.new(:range, :price)
    
    class PhoneNumber < ::APISmith::Smash
      property :iso,         required: true, from: :ISO
      property :sms_enabled, required: true, from: 'SMS Enabled',      transformer: BooleanTransformer
      property :cost,        required: true, from: 'Price /num/month', transformer: MoneyTransformer
    end
  end
end