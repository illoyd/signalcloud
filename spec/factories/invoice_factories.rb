FactoryGirl.define do
  factory :invoice do
    date_from   { 30.days.ago.beginning_of_day }
    date_to     { 1.day.ago.end_of_day }
  end
end
