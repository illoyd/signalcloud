FactoryGirl.define do

  factory :organization do
    sid                 { SecureRandom.hex(16) }
    auth_token          { SecureRandom.hex(16) }
    label               'Test Account'
    balance             9.99
    association         :contact_address, factory: :white_house_address
    association         :billing_address, factory: :address
    account_plan        { create :payg_account_plan }
    #test_twilio
    #test_freshbooks_client

    factory :test_organization do
      label               'White House'
      test_freshbooks
    end
    
    factory :master_organization do
      label               'signalcloud'
      master_twilio
      test_freshbooks
    end
    
    trait :with_sid_and_token do
      sid               '6cc9f11f2c466d4f443453257eb76a2a'
      auth_token        '247e210af4ee43c1509e5c8508184bf5'
    end
    
    #trait :missing_twilio do
    #  twilio_account_sid  nil
    #  twilio_auth_token   nil
    #end
    
    trait :test_twilio do
      twilio_account_sid      { ENV['TWILIO_TEST_ACCOUNT_SID'] }
      twilio_auth_token       { ENV['TWILIO_TEST_AUTH_TOKEN'] }
      twilio_application_sid  { ENV['TWILIO_APPLICATION'] }
    end
    
    trait :master_twilio do
      twilio_account_sid      { ENV['TWILIO_MASTER_ACCOUNT_SID'] }
      twilio_auth_token       { ENV['TWILIO_MASTER_AUTH_TOKEN'] }
      twilio_application_sid  { ENV['TWILIO_APPLICATION'] }
    end
    
    trait :test_freshbooks do
      freshbooks_id       2
    end
    
    trait :with_users do
      ignore do
        users_count 3
      end
      after(:create) do |organization, evaluator|
        evaluator.users_count.times do
          organization.user_roles.create user: FactoryGirl.create(:user)
        end
      end
    end
    
  end

end
