FactoryGirl.define do

  factory :account do
    account_sid         { SecureRandom.hex(16) }
    auth_token          { SecureRandom.hex(16) }
    label               'Test Account'
    balance             9.99
    twilio_account_sid  { ENV['TWILIO_TEST_ACCOUNT_SID'] }
    twilio_auth_token   { ENV['TWILIO_TEST_AUTH_TOKEN'] }
    association         :primary_address, factory: :white_house_address
    association         :secondary_address, factory: :address
    account_plan

    ignore do
      users_count 3
    end
    after(:create) do |account, evaluator|
      FactoryGirl.create_list(:user, evaluator.users_count, account: account)
    end

    factory :test_account do
      label               'White House'
      # twilio_account_sid  { ENV['TWILIO_TEST_ACCOUNT_SID'] }
      # twilio_auth_token   { ENV['TWILIO_TEST_AUTH_TOKEN'] }
      freshbooks_id       2
    end
    
    factory :master_account do
      label               'ticketplease'
      twilio_account_sid  { ENV['TWILIO_MASTER_ACCOUNT_SID'] }
      twilio_auth_token   { ENV['TWILIO_MASTER_AUTH_TOKEN'] }
      freshbooks_id       2
    end
    
  end

end
