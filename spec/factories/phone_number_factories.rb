FactoryGirl.define do

  factory :phone_number, aliases: [ :us_phone_number ] do
    number                      { random_us_number() }
    twilio_phone_number_sid     { 'PN' + SecureRandom.hex(16) }
    account
    
    trait :with_costs do
      provider_cost    { random_cost() }
      our_cost         { random_cost() }
    end
    
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
    
    trait :with_costs do
      provider_cost             { random_cost() }
      our_cost                  { random_cost() }
    end
    
    trait :ignore_unsolicited_sms do
      unsolicited_sms_action    PhoneNumber::IGNORE
    end
    
    trait :reply_to_unsolicited_sms do
      unsolicited_sms_action    PhoneNumber::REPLY
      unsolicited_sms_message   'Hello there - I\'m an SMS reply.'
    end
    
    trait :reject_unsolicited_call do
      unsolicited_call_action   PhoneNumber::REJECT
    end
    
    trait :busy_for_unsolicited_call do
      unsolicited_call_action   PhoneNumber::BUSY
    end
    
    trait :reply_to_unsolicited_call do
      unsolicited_call_action   PhoneNumber::REPLY
      unsolicited_call_message  'Hello there - I\'m a voice reply.'
      unsolicited_call_language PhoneNumber::AMERICAN_ENGLISH
      unsolicited_call_voice    PhoneNumber::WOMAN_VOICE
    end

  end

end
