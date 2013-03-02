FactoryGirl.define do

  factory :account do
    account_sid         { SecureRandom.hex(16) }
    auth_token          { SecureRandom.hex(16) }
    label               'Test Account'
    balance             9.99
    association         :primary_address, factory: :white_house_address
    association         :secondary_address, factory: :address
    account_plan
    #test_twilio
    #test_freshbooks_client

    factory :test_account do
      label               'White House'
      test_freshbooks
    end
    
    factory :master_account do
      label               'ticketplease'
      master_twilio
      test_freshbooks
    end
    
    #trait :missing_twilio do
    #  twilio_account_sid  nil
    #  twilio_auth_token   nil
    #end
    
    trait :test_twilio do
      twilio_account_sid  { ENV['TWILIO_TEST_ACCOUNT_SID'] }
      twilio_auth_token   { ENV['TWILIO_TEST_AUTH_TOKEN'] }
      twilio_application_sid  'AP94035dba3ec54b70bd38ae24fc032387'
    end
    
    trait :master_twilio do
      twilio_account_sid  { ENV['TWILIO_MASTER_ACCOUNT_SID'] }
      twilio_auth_token   { ENV['TWILIO_MASTER_AUTH_TOKEN'] }
      twilio_application_sid  'APb4cd58755fcc47dcb3cd329ad2d27a55'
    end
    
    trait :test_freshbooks do
      freshbooks_id       2
    end
    
    trait :with_users do
      ignore do
        users_count 3
      end
      after(:create) do |account, evaluator|
        FactoryGirl.create_list(:user, evaluator.users_count, account: account)
      end
    end
    
  end

end
