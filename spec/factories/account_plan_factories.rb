FactoryGirl.define do

  factory :account_plan do
    label         'Dev'
    
    trait :default do
      default     true
    end

    factory :payg_account_plan do
      label         'Pay-as-You-Go'
      phone_add     -1
      call_in_add   -0.00
      sms_in_add    -0.01
      sms_out_add   -0.01
    end

    factory :dedicated_account_plan do
      label         'Dedicated'
      month         -250
      phone_add     0
      call_in_add   -0.00
      sms_in_add    -0.01
      sms_out_add   -0.01
    end

    factory :special_account_plan do
      label         'Special'
      month         -50
      phone_mult    0.1
      call_in_mult  0.1
      sms_in_mult   0.1
      sms_out_mult  0.1
    end

    factory :ridiculous_account_plan do
      label         'Special'
      month         -777
      phone_add     -1.1
      phone_mult    0.5
      call_in_add   -4
      call_in_mult  0.4
      sms_in_add    -3
      sms_in_mult   0.3
      sms_out_add   -2
      sms_out_mult  0.2
    end
  end

end
