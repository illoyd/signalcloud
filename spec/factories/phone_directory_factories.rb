FactoryGirl.define do

  factory :phone_directory do
    account
    label         "Baby's first directory"
    description   "A test directory."
  end
  
  factory :phone_directory_entry do
    country       nil
  end

end
