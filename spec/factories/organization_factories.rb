def address
  Address.new(
    Faker::Name.first_name, Faker::Name.last_name,
    Faker::Internet.email,
    '+12121234567',
    Faker::Address.street_address,
    Faker::Address.secondary_address,
    Faker::Address.city,
    Faker::Address.state_abbr,
    Faker::Address.zip_code,
    'US'
  )
end

def white_house_address
  Address.new( 'Barack', 'Obama', 'theprez@signalcloudapp.com', '+12021234568', 'The White House', '1600 Pennsylvania Ave NW', 'Washington', 'DC', '20500', 'US' )
end

FactoryGirl.define do

  factory :organization do
    sid                 { SecureRandom.hex(16) }
    auth_token          { SecureRandom.hex(16) }
    label               { Faker::Company.name }
    association         :owner, factory: :user
    contact_address     white_house_address
    billing_address     address
    use_billing_as_contact_address false
    workflow_state 'ready'
    #with_mock_comms

    association         :account_plan, factory: :account_plan, strategy: :build

    factory :test_organization do
      label               'White House'
      test_twilio
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
    
    trait :test_twilio do
      after(:build) do |org|
        unless org.communication_gateway_for? :twilio
          org.communication_gateways << build( :twilio_communication_gateway, :test, organization: org )
        end
      end
    end
    
    trait :master_twilio do
      after(:build) do |org|
        unless org.communication_gateway_for? :twilio
          org.communication_gateways << build( :twilio_communication_gateway, :master, organization: org )
        end
      end
    end
    
    trait :with_mock_comms do
      with_mock_communication_gateway
    end
    
    trait :with_mock_communication_gateway do
      after(:build) do |org|
        unless org.communication_gateway_for? :mock
          org.communication_gateways << build( :mock_communication_gateway, :test, organization: org )
        end
      end
    end
    
    trait :with_twilio do
      test_twilio
    end
    
    trait :with_freshbooks do
      test_freshbooks
    end
    
    trait :with_braintree do
      # TODO braintree_id 100
    end
    
    trait :test_freshbooks do
      # freshbooks_id 2
      association :accounting_gateway, factory: [ :fresh_books_accounting_gateway ]
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
