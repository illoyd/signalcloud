FactoryGirl.define do

  factory :user do
    organization
    first_name         'John'
    last_name          'Doe'
    sequence(:email)   { |n| "user#{n}@signalcloudapp.com" }
    password           { SecureRandom.hex(4) }
    
    User::ROLES.each do |role|
      factory "#{role}_user".to_sym do
        roles_mask       { User.translate_roles [ role ] }
      end
    end

    #factory :super_user do
    #  roles_mask       { User.translate_roles [ :super_user ] }
    #end
    
    factory :manage_organization_permissions_user do
      roles_mask       { User.translate_roles [ :manage_organization ] }
    end
    
    factory :manage_users_permissions_user do
      roles_mask       { User.translate_roles [ :manage_users ] }
    end
    
    factory :manage_stencils_permissions_user do
      roles_mask       { User.translate_roles [ :manage_stencils ] }
    end
    
    factory :manage_phone_numbers_permissions_user do
      roles_mask       { User.translate_roles [ :manage_phone_numbers ] }
    end
    
    factory :manage_phone_books_permissions_user do
      roles_mask       { User.translate_roles [ :manage_phone_books ] }
    end
    
    factory :start_conversation_permissions_user do
      roles_mask       { User.translate_roles [ :start_conversation ] }
    end
    
    factory :force_conversation_permissions_user do
      roles_mask       { User.translate_roles [ :force_conversation ] }
    end
    
    factory :manage_ledger_entries_permissions_user do
      roles_mask       { User.translate_roles [ :manage_ledger_entries ] }
    end
  end

end
