FactoryGirl.define do

  factory :fresh_books_accounting_gateway do
    organization
    
    trait :ready do
      workflow_state  'ready'
      remote_sid 2
    end

  end

end
