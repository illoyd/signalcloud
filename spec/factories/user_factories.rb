FactoryGirl.define do

  factory :user do
    nickname           { Faker::Name.first_name }
    name               { Faker::Name.name }
    email              { Faker::Internet.email }
    password           { Faker::Internet.password }
    
    factory "affiliated_user".to_sym do
      after(:create) do |user, evaluator|
        user.user_roles.create organization: FactoryGirl.create(:organization), roles: []
      end
    end

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
