require 'test_helper'

class PhoneNumberTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  UNAVAILABLE_NUMBER = '+15005550000'
  INVALID_NUMBER = '+15005550001'
  AVAILABLE_NUMBER = '+15005550006'
  
  UNAVAILABLE_AREACODE = '533'
  AVAILABLE_AREACODE = '500'
  
  test "should review validations" do
    # Account...
    should belong_to(:account)
    should validate_presense_of(:account)
    
    # Other relationships
    should have_many(:phone_books)
    should have_many(:phone_book_entries)
    
    # Values and attributes
    should allow_mass_assignment_of(:number, :twilio_phone_number_sid, :account_id, :our_cost, :provider_cost)
    should validate_presense_of(:number)
    should validate_presense_of(:twilio_phone_number_sid)
    should validate_numericality_of(:our_cost)
    should validate_numericality_of(:provider_cost)
  end
  
  test "should save phone number (with temporary twilio SID)" do
    # Build a basic phone number and save
    account = accounts( :test_account )
    phone_number = account.phone_numbers.build( { number: AVAILABLE_NUMBER } )
    phone_number.twilio_phone_number_sid = 'TEMP'
    assert phone_number.valid?, 'Phone number failed validity checks'
    
    # Save number
    assert_difference( 'account.phone_numbers.count' ) do
      assert phone_number.save, "Failed to save phone_number"
    end
  end
  
  test 'buy available phone number' do
    account = accounts( :test_account )
    phone_number = account.phone_numbers.new( { number: AVAILABLE_NUMBER } )
    assert_nil phone_number.twilio_phone_number_sid

    # Make purchase
    assert_nothing_raised( Twilio::REST::RequestError ) { phone_number.buy }
    assert_not_nil phone_number.twilio_phone_number_sid
  end
  
  test 'cannot buy invalid phone number' do
    account = accounts( :test_account )
    phone_number = account.phone_numbers.new( { number: INVALID_NUMBER } )
    assert_nil phone_number.twilio_phone_number_sid

    # Make purchase
    assert_raise( Twilio::REST::RequestError ) { phone_number.buy }
    assert_nil phone_number.twilio_phone_number_sid
  end
  
  test 'cannot buy unavailable phone number' do
    account = accounts( :test_account )
    phone_number = account.phone_numbers.new( { number: UNAVAILABLE_NUMBER } )
    assert_nil phone_number.twilio_phone_number_sid

    # Make purchase
    assert_raise( Twilio::REST::RequestError ) { phone_number.buy }
    assert_nil phone_number.twilio_phone_number_sid
  end
  
end
