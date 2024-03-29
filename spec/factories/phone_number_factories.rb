FactoryGirl.define do

  factory :phone_number, aliases: [ :internal_number, :us_phone_number ] do

    trait :with_organization do
      association :organization, :with_mock_comms, strategy: :build
    end
    
    trait :with_gateway do
      ignore { comm_type nil }
      communication_gateway     { comm_type ? (organization.save; organization.communication_gateway_for(comm_type)) : organization.communication_gateways.first }
    end

    sequence(:number)           { |n| '+1%010d' % ( 6000000000 + n ) }

    factory :valid_phone_number do
      number                    { Twilio::VALID_NUMBER }
    end
    
    factory :invalid_phone_number do
      number                    { Twilio::INVALID_NUMBER }
    end
    
    factory :unavailable_phone_number do
      number                    { Twilio::UNAVAILABLE_NUMBER }
    end
    
    factory :uk_phone_number, aliases: [:gb_phone_number] do
      sequence(:number)         { |n| '+4479%08d' % n }
    end
    
    factory :ca_phone_number do
      sequence(:number)         { |n| '+1416%07d' % n }
    end
    
    trait :with_provider_sid do
      provider_sid              { 'PN' + SecureRandom.hex(16) }
    end
    
    trait :with_twilio_sid do
      with_provider_sid
    end

    trait :with_fixed_twilio_sid do
      provider_sid              { 'PN465138f996b14d147c5fb4143bb30bea' }
    end
    
    trait :active do
      with_provider_sid
      workflow_state            'active'
    end
    
    trait :inactive do
      workflow_state            'inactive'
    end
    
    trait :with_costs do
      cost                      { random_cost() }
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
