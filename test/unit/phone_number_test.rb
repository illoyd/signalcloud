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
  
  test "should save phone number" do
    # Build a basic phone number and save
    account = accounts( :test_account )
    phone_number = account.phone_numbers.build( { number: AVAILABLE_NUMBER } )
    phone_number.twilio_phone_number_sid = 'TEMP'
    assert phone_number.valid?
    
    # Save number
    assert_difference( 'account.phone_numbers.count' ) do
      assert phone_number.save, "Failed to save phone_number"
    end
  end
  
  test "should not save phone number" do
    # Get test account
    account = accounts( :test_account )
    
    # Build a new generic phone number missing some details
    phone_number = account.phone_numbers.build( { number: nil } )
    assert !phone_number.valid?
    
    phone_number.number = AVAILABLE_NUMBER
    assert !phone_number.valid?
    
    phone_number.twilio_phone_number_sid = 'TEMP'
    assert !phone_number.valid?
    
    # Save number (and fail)
    assert_no_difference( 'account.phone_numbers.count' ) do
      assert !phone_number.save, "Saved phone_number when model was invalid"
    end
  end
  
  test "should not save (missing account) phone number" do
    # Get test account
    account = accounts( :test_account )
    
    # Build a new generic phone number missing some details
    phone_number = PhoneNumber.new( { number: nil } )
    assert !phone_number.valid?
    
    # Save number (and fail)
    assert_no_difference( 'account.phone_numbers.count' ) do
      assert !phone_number.save, "Saved phone_number when model was invalid"
    end

    phone_number.number = AVAILABLE_NUMBER
    assert !phone_number.valid?
    
    # Save number (and fail)
    assert_no_difference( 'account.phone_numbers.count' ) do
      assert !phone_number.save, "Saved phone_number when model was invalid"
    end

    phone_number.twilio_phone_number_sid = 'TEMP'
    assert !phone_number.valid?
    
    # Save number (and fail)
    assert_no_difference( 'account.phone_numbers.count' ) do
      assert !phone_number.save, "Saved phone_number when model was invalid"
    end

    phone_number.account = accounts( :test_account )
    
    # Save number (and fail)
    assert_no_difference( 'account.phone_numbers.count' ) do
      assert !phone_number.save, "Saved phone_number when model was invalid"
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
