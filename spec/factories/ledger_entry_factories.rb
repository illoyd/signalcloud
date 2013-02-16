FactoryGirl.define do

  factory :ledger_entry do
    account
    item { |instance| instance.account }
    narrative   'Generic'
    
    trait :with_value do
      value { random_price() }
    end
    
    trait :settled do
      settled_at { DateTime.now }
    end
    
    trait :pending do
      settled_at nil
    end
  end

end
