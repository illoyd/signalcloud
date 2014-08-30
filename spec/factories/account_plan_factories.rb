FactoryGirl.define do

  factory :account_plan do
    label         'Dev'
    
    trait :default do
      default     true
    end

    factory :payg_account_plan do
      label         'Pay-as-You-Go'

      phone_number_pricer_class 'Pricers::SimplePhoneNumberPricer'
      phone_number_pricer_config Hash.new({ US: '3' })

      conversation_pricer_class 'Pricers::SimpleConversationPricer'
      conversation_pricer_config Hash.new({ US: '0.1' })
    end

    factory :dedicated_account_plan do
      label         'Dedicated'
      month         250

      phone_number_pricer_class 'Pricers::SimplePhoneNumberPricer'
      phone_number_pricer_config Hash.new({ US: '1.5' })

      conversation_pricer_class 'Pricers::SimpleConversationPricer'
      conversation_pricer_config Hash.new({ US: '0.08' })
    end

    factory :free_account_plan do
      label         'All Inclusive'
      month         1000
      phone_number_pricer_class 'Pricers::FreePricer'
      conversation_pricer_class 'Pricers::FreePricer'
    end

    factory :at_cost_account_plan do
      label         'At Cost'
      phone_number_pricer_class 'Pricers::FreePricer'
      conversation_pricer_class 'Pricers::FreePricer'
    end
  end

end
