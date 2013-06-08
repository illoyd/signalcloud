FactoryGirl.define do

  factory :braintree_payment_gateway do
    organization
    workflow_state       'ready'

    trait :master do
      remote_sid         { 2 }
    end
    
    trait :test do
      remote_sid         { 1 }
    end
  end

end
