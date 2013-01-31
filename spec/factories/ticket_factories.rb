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
  end

end
