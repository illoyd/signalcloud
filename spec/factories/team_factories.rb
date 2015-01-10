# This will guess the User class
FactoryGirl.define do

  factory :team do
    name        { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    owner       { create(:user) }
  end

end