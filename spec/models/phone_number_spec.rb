require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber do
  fixtures :accounts, :phone_numbers
  before { VCR.insert_cassette 'phone_number', record: :new_episodes }
  after { VCR.eject_cassette }
  
  before :each do
    #@phone_number = phone_numbers(:test)
    @account = accounts( :test_account )
  end

  # Manage all validations
  describe "validations" do
    # Allow mass assignment
    [ :account_id, :twilio_phone_number_sid, :number, :our_cost, :provider_cost ].each do |entry|
      it { should allow_mass_assignment_of(entry) }
    end
    
    # Belong-To
    it { should belong_to(:account) }

    # Have-Many
    [ :phone_directories, :phone_directory_entries ].each do |entry|
      it { should have_many(entry) }
    end
    
    # Validate presence
    [ :account_id, :twilio_phone_number_sid, :number ].each do |entry|
      it { should validate_presence_of(entry) }
    end
    
    # Validate numericality
    [ :account_id, :our_cost, :provider_cost ].each do |entry|
      it { should validate_numericality_of(entry) }
    end
        
    # Uniqueness
    it { should validate_uniqueness_of(:twilio_phone_number_sid) }
    
    # Twilio SID
    it { should ensure_length_of(:twilio_phone_number_sid).is_equal_to(Twilio::SID_LENGTH) }
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
  
  describe 'unsolicited call helpers' do
    context 'when action is REJECT' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::REJECT) }
      its(:'should_reject_unsolicited_call?') { should be_true }
      its(:'should_play_busy_for_unsolicited_call?') { should be_false }
      its(:'should_reply_to_unsolicited_call?') { should be_false }
    end
    context 'when action is BUSY' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::BUSY) }
      its(:'should_reject_unsolicited_call?') { should be_false }
      its(:'should_play_busy_for_unsolicited_call?') { should be_true }
      its(:'should_reply_to_unsolicited_call?') { should be_false }
    end
    context 'when action is REPLY' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::REPLY) }
      its(:'should_reject_unsolicited_call?') { should be_false }
      its(:'should_play_busy_for_unsolicited_call?') { should be_false }
      its(:'should_reply_to_unsolicited_call?') { should be_true }
    end
  end
  
  describe 'unsolicited sms helpers' do
    context 'when action is IGNORE' do
      subject { build(:phone_number, unsolicited_sms_action: PhoneNumber::IGNORE) }
      its(:'should_ignore_unsolicited_sms?') { should be_true }
      its(:'should_reply_to_unsolicited_sms?') { should be_false }
    end
    context 'when action is REPLY' do
      subject { build(:phone_number, unsolicited_sms_action: PhoneNumber::REPLY) }
      its(:'should_ignore_unsolicited_sms?') { should be_false }
      its(:'should_reply_to_unsolicited_sms?') { should be_true }
    end
  end
  
  # Manage costs
  describe '#cost' do
    it 'interprete nil to 0' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = nil
      phone_number.provider_cost = nil
      phone_number.cost.should == 0
    end
    it 'accept 0, number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = 0
      phone_number.provider_cost = 1.3
      phone_number.cost.should == 1.3
    end
    it 'accept number, 0' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = 2.5
      phone_number.provider_cost = 0
      phone_number.cost.should == 2.5
    end
    it 'accept number, number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = 2.5
      phone_number.provider_cost = 1.3
      phone_number.cost.should == 3.8
    end
    it 'accept number, number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = 2.5
      phone_number.provider_cost = 1.3
      phone_number.cost.should == 3.8
    end
    it 'accept -number, number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = -2.5
      phone_number.provider_cost = 1.3
      phone_number.cost.should == -1.2
    end
    it 'accept number, -number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = 2.5
      phone_number.provider_cost = -1.3
      phone_number.cost.should == 1.2
    end
    it 'accept -number, -number' do
      phone_number = phone_numbers(:test_us)
      phone_number.our_cost = -2.5
      phone_number.provider_cost = -1.3
      phone_number.cost.should == -3.8
    end
  end

end
