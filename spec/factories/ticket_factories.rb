FactoryGirl.define do

  factory :ticket do
    appliance
    from_number               Twilio::VALID_NUMBER
    to_number                 Twilio::VALID_NUMBER
    expiry                    180.seconds.from_now
    question                  'Hello, I am a question.'
    expected_confirmed_answer 'yes'
    expected_denied_answer    'no'
    confirmed_reply           'Right answer!'
    denied_reply              'The other right answer!'
    failed_reply              'Wrong answer!'
    expired_reply             'Took too long!'
    
    trait :challenge_sent do
      status                  Ticket::CHALLENGE_SENT
      challenge_sent          { DateTime.now }
      challenge_status        Message::SENT
    end

    trait :response_received do
      response_received       { DateTime.now }
    end

    trait :reply_sent do
      reply_sent              { DateTime.now }
      reply_status            Message::SENT
    end

    trait :confirmed do
      status                  Ticket::CONFIRMED
    end

    trait :denied do
      status                  Ticket::DENIED
    end

    trait :failed do
      status                  Ticket::FAILED
    end

    trait :expired do
      status                  Ticket::EXPIRED
    end

  end

end