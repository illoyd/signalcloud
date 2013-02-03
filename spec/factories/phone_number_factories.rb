FactoryGirl.define do

  factory :phone_number, aliases: [ :us_phone_number ] do
    number                      { random_us_number() }
    twilio_phone_number_sid     { 'PN' + SecureRandom.hex(16) }
    provider_cost               { random_cost() }
    our_cost                    { random_cost() }
    account
    
    factory :valid_phone_number do
      number                    { Twilio::VALID_NUMBER }
    end
    
    factory :invalid_phone_number do
      number                    { Twilio::INVALID_NUMBER }
    end
    
    factory :uk_phone_number do
      number                    { random_uk_number() }
    end
    
    factory :ca_phone_number do
      number                    { random_ca_number() }
    end
  end

end
