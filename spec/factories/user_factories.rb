FactoryGirl.define do

  factory :user do
    nickname           'John'
    name               'Johnathan Doe'
    sequence(:email)   { |n| "user#{n}@signalcloudapp.com" }
    password           { SecureRandom.hex(4) }
    
    UserRole::ROLES.each do |role|
      factory "#{role}_user".to_sym do
        after(:create) do |user, evaluator|
          user.user_roles.create organization: FactoryGirl.create(:organization), roles: [role]
        end
      end
    end
  end

    #factory :super_user do
    #  roles_mask       { User.translate_roles [ :super_user ] }
    #end
    
end
