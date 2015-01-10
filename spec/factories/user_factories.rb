# This will guess the User class
FactoryGirl.define do

  factory :user do
    name     { Faker::Name.name }
    nickname { Faker::Name.first_name }
    email    { "#{ Faker::Internet.user_name }@signalcloudapp.com" }
    password { Faker::Internet.password }
    
    before(:create) do |user|
      user.skip_confirmation!
    end
  end

end