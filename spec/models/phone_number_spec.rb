require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber, :vcr => { :cassette_name => "phone_number" } do
  
  let(:account) { create :account, :test_twilio, :with_sid_and_token }

  # Manage all validations
  describe "validations" do
    before(:all) { 3.times { create :phone_number } }

    # Allow mass assignment
    [ :number, :twilio_phone_number_sid, :account_id, :our_cost, :provider_cost, :unsolicited_sms_action, :unsolicited_sms_message, :unsolicited_call_action, :unsolicited_call_message, :unsolicited_call_language, :unsolicited_call_voice ].each do |entry|
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
  
  describe '.find_by_number' do
    let(:valid_number) { '+15551234567' }
    let(:unknown_number) { '+18001234567' }
    subject { create :phone_number, number: valid_number }
    
    it 'finds valid number' do
      PhoneNumber.find_by_number(subject.number).first.should be_a( PhoneNumber )
    end
    
    it 'cannot find a number' do
      PhoneNumber.find_by_number(unknown_number).should be_empty
    end
    
    it 'throws error on inappropriate number' do
      expect{ PhoneNumber.find_by_number('hello') }.to raise_error
    end
    
    it 'throws error on nil' do
      expect{ PhoneNumber.find_by_number(nil) }.to raise_error
    end
    
    it 'throws error on empty string' do
      expect{ PhoneNumber.find_by_number('') }.to raise_error
    end
    
    it 'throws error on blank string' do
      expect{ PhoneNumber.find_by_number('   ') }.to raise_error
    end
    
  end

  # Manage creation
#   describe ".new" do
#     it "should save with temporary SID" do
#       count_of_phone_numbers = account.phone_numbers.count
#       pn = PhoneNumber.create( { account_id: account.id, number: '+12125551234', twilio_phone_number_sid: 'TEMPORARY1234567890123456789012345' } )
#       account.phone_numbers.count.should == count_of_phone_numbers + 1
#     end
#   end
  
  # Manage buying
  describe ".buy" do
    it "should buy a valid and available number" do
      count_of_phone_numbers = account.phone_numbers.count
      pn = account.phone_numbers.build( { number: AVAILABLE_NUMBER } )
      expect { pn.buy() }.to_not raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to_not raise_error(StandardError)
      account.phone_numbers.count.should == count_of_phone_numbers + 1
    end

    it "should not buy an invalid number" do
      count_of_phone_numbers = account.phone_numbers.count
      pn = account.phone_numbers.build( { number: INVALID_NUMBER } )
      expect { pn.buy() }.to raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to raise_error( StandardError )
      account.phone_numbers.count.should == count_of_phone_numbers
    end

    it "should not buy an unavailable number" do
      count_of_phone_numbers = account.phone_numbers.count
      pn = account.phone_numbers.build( { number: UNAVAILABLE_NUMBER } )
      expect { pn.buy() }.to raise_error(Twilio::REST::RequestError)
      expect { pn.save!() }.to raise_error( StandardError )
      account.phone_numbers.count.should == count_of_phone_numbers
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
  
  describe '#has_cost?' do

    context 'when both costs are present' do
      subject { build :phone_number, provider_cost: -1.00, our_cost: -0.50 }
      its(:'has_cost?') { should be_true }
    end
    context 'when only provider_cost is present' do
      subject { build :phone_number, provider_cost: -1.00, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end
    context 'when only our_cost is present' do
      subject { build :phone_number, provider_cost: nil, our_cost: -0.50 }
      its(:'has_cost?') { should be_false }
    end
    context 'when both costs are not present' do
      subject { build :phone_number, provider_cost: nil, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end

  end
  
  describe '#provider_cost=' do

    context 'when cost is not nil' do
      let(:provider_cost) { -1.00 }
      subject { build :phone_number, provider_cost: nil, our_cost: nil }
      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(provider_cost)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }
      end
    end

    context 'when cost is nil' do
      let(:provider_cost) { nil }
      subject { build :phone_number, provider_cost: -1.00, our_cost: -0.50 }
      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(nil)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }.to(nil)
      end
    end

  end
  
  describe '#cost' do
    [ [nil,nil], [nil,1], [1,nil], [1,1], [1,-1], [-1,1], [0.25,-0.32] ].each do |costs|
      it "properly sums provider:#{costs.first} and our:#{costs.second}" do
        phone_number = build :phone_number, provider_cost: costs.first, our_cost: costs.second
        phone_number.cost.should == costs.reject{ |entry| entry.nil? }.sum
      end
    end
  end

end
