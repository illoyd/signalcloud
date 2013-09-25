FactoryGirl.define do

  factory :conversation do
    stencil
    internal_number           Twilio::VALID_NUMBER
    customer_number           Twilio::VALID_NUMBER
    expires_at                180.seconds.from_now
    question                  'Hello, I am a question.'
    expected_confirmed_answer 'yes'
    expected_denied_answer    'no'
    confirmed_reply           'Right answer!'
    denied_reply              'The other right answer!'
    failed_reply              'Wrong answer!'
    expired_reply             'Took too long!'
    
    trait :challenge_sent do
      workflow_state          'listening'
      challenge_sent_at       { DateTime.now }
      challenge_status        'sent'
    end

    trait :response_received do
      response_received_at    { DateTime.now }
    end

    trait :reply_sent do
      reply_sent_at           { DateTime.now }
      reply_status            'sent'
    end

    trait :confirmed do
      challenge_sent
      response_received
      workflow_state          'confirmed'
    end

    trait :denied do
      challenge_sent
      response_received
      workflow_state          'denied'
    end

    trait :failed do
      challenge_sent
      response_received
      workflow_state          'failed'
    end

    trait :expired do
      challenge_sent
      workflow_state          'expired'
    end
    
    trait :with_webhook_uri do
      webhook_uri             'https://us.signalcloudapp.com/bucket'
    end

  end

end
