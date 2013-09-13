FactoryGirl.define do

  factory :conversation do
    stencil
    from_number               Twilio::VALID_NUMBER
    to_number                 Twilio::VALID_NUMBER
    expires_at                180.seconds.from_now
    question                  'Hello, I am a question.'
    expected_confirmed_answer 'yes'
    expected_denied_answer    'no'
    confirmed_reply           'Right answer!'
    denied_reply              'The other right answer!'
    failed_reply              'Wrong answer!'
    expired_reply             'Took too long!'
    
    trait :challenge_sent do
      status                  Conversation::CHALLENGE_SENT
      challenge_sent_at       { DateTime.now }
      challenge_status        Message::SENT
    end

    trait :response_received do
      response_received_at    { DateTime.now }
    end

    trait :reply_sent do
      reply_sent_at           { DateTime.now }
      reply_status            Message::SENT
    end

    trait :confirmed do
      challenge_sent
      response_received
      status                  Conversation::CONFIRMED
    end

    trait :denied do
      challenge_sent
      response_received
      status                  Conversation::DENIED
    end

    trait :failed do
      challenge_sent
      response_received
      status                  Conversation::FAILED
    end

    trait :expired do
      challenge_sent
      status                  Conversation::EXPIRED
    end
    
    trait :with_webhook_uri do
      webhook_uri             'https://us.signalcloudapp.com/bucket'
    end

  end

end
