FactoryGirl.define do

  factory :unsolicited_call do
    phone_number
    customer_number     Twilio::VALID_NUMBER
    provider_sid        'SM' + SecureRandom.hex(16)
    received_at         { DateTime.now }
    
    trait :with_prices do
      provider_price    { random_cost() }
      our_price         { random_cost() }
    end
    
  end

end
