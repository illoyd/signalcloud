FactoryGirl.define do

  factory :address do
    line1       'Test Address'
    line2       nil
    city        'Washington'
    region      'DC'
    postcode    '20500'
    country     'US'

    factory :white_house_address do
      line1       '1600 Pennsylvania Ave NW'
      line2       nil
      city        'Washington'
      region      'DC'
      postcode    '20500'
      country     'US'
    end
  end

end
