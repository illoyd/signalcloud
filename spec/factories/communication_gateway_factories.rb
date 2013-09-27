FactoryGirl.define do

  factory :twilio_communication_gateway do
    organization

    trait :master do
      workflow_state     'ready'
      remote_sid         { ENV['TWILIO_MASTER_ACCOUNT_SID'] }
      remote_token       { ENV['TWILIO_MASTER_AUTH_TOKEN'] }
      remote_application { ENV['TWILIO_APPLICATION'] }
    end
    
    trait :test do
      workflow_state     'ready'
      remote_sid         { ENV['TWILIO_TEST_ACCOUNT_SID'] }
      remote_token       { ENV['TWILIO_TEST_AUTH_TOKEN'] }
      remote_application { ENV['TWILIO_APPLICATION'] }
    end
  end

end
