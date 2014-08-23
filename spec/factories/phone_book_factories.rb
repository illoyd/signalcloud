FactoryGirl.define do

  factory :phone_book do
    label         "Baby's first book"
    description   "A test book."
    
    trait :with_organization do
      association :organization, :with_mock_comms, strategy: :build
    end

    trait :with_phone_numbers do
      ignore do
        us 1
        ca 0
        gb 0
      end

      after(:build) do |object, evaluator|
        phone_numbers = build_list :us_phone_number, us, organization: object.organization, communication_gateway: object.organization.communication_gateways.first
        phone_numbers.each { |pn| object.phone_book_entries.build phone_number: phone_number, country: 'US' }

        phone_numbers = build_list :ca_phone_number, us, organization: object.organization, communication_gateway: object.organization.communication_gateways.first
        phone_numbers.each { |pn| object.phone_book_entries.build phone_number: phone_number, country: 'CA' }

        phone_numbers = build_list :gb_phone_number, us, organization: object.organization, communication_gateway: object.organization.communication_gateways.first
        phone_numbers.each { |pn| object.phone_book_entries.build phone_number: phone_number, country: 'GB' }
      end
    end

  end
  
  factory :phone_book_entry do
    country       nil
  end

end
