require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :accounts, :phone_numbers
  
  before :each do
    #@phone_number = phone_numbers(:test)
    @account = accounts( :test_account )
  end

  # Manage all validations
  describe "validations" do
    # Account...
    it { should belong_to(:account) }
    #it { should validate_presence_of(:account) }
    it { should validate_presence_of(:account_id) }
    it { should validate_numericality_of(:account_id) }
    it { should allow_mass_assignment_of( :account_id ) }

    # Other relationships
    it { should have_many(:phone_directories) }
    it { should have_many(:phone_directory_entries) }
    
    # Values and attributes
    it { should validate_presence_of(:twilio_phone_number_sid) }
    it { should allow_mass_assignment_of( :twilio_phone_number_sid ) }
    it { should validate_uniqueness_of(:twilio_phone_number_sid) }
    it { should ensure_length_of(:twilio_phone_number_sid).is_equal_to(Twilio::SID_LENGTH) }

    it { should allow_mass_assignment_of( :number ) }
    it { should validate_presence_of(:number) }
    
    it { should allow_mass_assignment_of( :our_cost ) }
    it { should validate_numericality_of(:our_cost) }

    it { should validate_numericality_of(:provider_cost) }
    it { should allow_mass_assignment_of( :provider_cost ) }
  end

  # Manage creation
  describe ".new" do
    it "should save with temporary SID" do
      count_of_phone_numbers = @account.phone_numbers.count
      pn = PhoneNumber.create( { account_id: @account.id, number: '+12125551234', twilio_phone_number_sid: 'TEMPORARY1234567890123456789012345' } )
      @account.phone_numbers.count.should == count_of_phone_numbers + 1
    end
  end
  
  # Manage buying
  describe ".buy" do
    it "should buy a valid and available number" do
      count_of_phone_numbers = @account.phone_numbers.count
      pn = @account.phone_numbers.build( { number: AVAILABLE_NUMBER } )
      expect { pn.buy() }.to_not raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to_not raise_error(StandardError)
      @account.phone_numbers.count.should == count_of_phone_numbers + 1
    end

    it "should not buy an invalid number" do
      count_of_phone_numbers = @account.phone_numbers.count
      pn = @account.phone_numbers.build( { number: INVALID_NUMBER } )
      expect { pn.buy() }.to raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to raise_error( StandardError )
      @account.phone_numbers.count.should == count_of_phone_numbers
    end

    it "should not buy an unavailable number" do
      count_of_phone_numbers = @account.phone_numbers.count
      pn = @account.phone_numbers.build( { number: UNAVAILABLE_NUMBER } )
      expect { pn.buy() }.to raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to raise_error( StandardError )
      @account.phone_numbers.count.should == count_of_phone_numbers
    end
  end

end
