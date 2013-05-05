FactoryGirl.define do

  factory :phone_book do
    account
    label         "Baby's first book"
    description   "A test book."
  end
  
  factory :phone_book_entry do
    country       nil
  end

end
