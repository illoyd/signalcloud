FactoryGirl.define do

  factory :user do
    account
    first_name         'John'
    last_name          'Doe'
    sequence(:email)   { |n| "user#{n}@signalcloudapp.com" }
    password           { SecureRandom.hex(4) }
    
    factory :shadow_account_permissions_user do
      roles_mask       { User.translate_roles [ :shadow_account ] }
    end
    
    factory :manage_account_permissions_user do
      roles_mask       { User.translate_roles [ :manage_account ] }
    end
    
    factory :manage_users_permissions_user do
      roles_mask       { User.translate_roles [ :manage_users ] }
    end
    
    factory :manage_appliances_permissions_user do
      roles_mask       { User.translate_roles [ :manage_appliances ] }
    end
    
    factory :manage_phone_numbers_permissions_user do
      roles_mask       { User.translate_roles [ :manage_phone_numbers ] }
    end
    
    factory :manage_phone_directories_permissions_user do
      roles_mask       { User.translate_roles [ :manage_phone_directories ] }
    end
    
    factory :start_ticket_permissions_user do
      roles_mask       { User.translate_roles [ :start_ticket ] }
    end
    
    factory :force_ticket_permissions_user do
      roles_mask       { User.translate_roles [ :force_ticket ] }
    end
    
    factory :manage_ledger_entries_permissions_user do
      roles_mask       { User.translate_roles [ :manage_ledger_entries ] }
    end
  end

end
