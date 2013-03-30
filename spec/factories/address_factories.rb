FactoryGirl.define do

  factory :address do
    first_name  'John Q'
    last_name   'Public'
    work_phone  '+12021234567'
    email       'john.q.public@signalcloudapp.com'
    line1       'Test Address'
    line2       nil
    city        'Washington'
    region      'DC'
    postcode    '20500'
    country     'US'

    factory :white_house_address do
      first_name  'Barack'
      last_name   'Obama'
      email       'theprez@signalcloudapp.com'
      line1       '1600 Pennsylvania Ave NW'
      line2       nil
      city        'Washington'
      region      'DC'
      postcode    '20500'
      country     'US'
    end
  end

end
