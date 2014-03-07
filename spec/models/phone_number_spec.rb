require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber, :vcr do

  let(:organization) { create :organization, :test_twilio, :with_sid_and_token }
  let(:comm_gateway) { organization.communication_gateways.first }
  
  # Manage all validations
  describe "validations" do
    before { 3.times { create :phone_number, organization: organization, communication_gateway: comm_gateway } }

    # Belong-To
    it { should belong_to(:organization) }
    it { should belong_to(:communication_gateway) }

    # Have-Many
    [ :phone_books, :phone_book_entries ].each do |entry|
      it { should have_many(entry) }
    end
    
    # Validate presence
    [ :organization, :number, :communication_gateway ].each do |entry|
      it { should validate_presence_of(entry) }
    end
    
    # Validate numericality
    it { should validate_numericality_of(:cost) }
  end
  
  describe '.find_by_number' do
    let(:valid_number)   { '+15551234567' }
    let(:unknown_number) { '+18001234567' }
    let(:phone_number)   { create :phone_number, number: valid_number, organization: organization, communication_gateway: comm_gateway }
    
    it 'finds valid number' do
      PhoneNumber.find_by_number(phone_number.number).first.should be_a( PhoneNumber )
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

  # Manage buying
  describe "#purchase" do
  
    context 'valid number' do

      context 'when inactive' do
        subject { create :valid_phone_number, organization: organization, communication_gateway: comm_gateway }
        its('can_purchase?')   { should be_true }
        its('can_refresh?')    { should be_false }
        its('can_unpurchase?') { should be_false }

        it 'purchases number' do
          expect { subject.purchase! }.not_to raise_error
        end
        it 'transitions to active state after purchasing' do
          expect { subject.purchase! }.to change(subject, :workflow_state).from('inactive').to('active')
        end
      end
      
      context 'when active' do
        subject { create :valid_phone_number, :active, :with_fixed_twilio_sid, organization: organization }
        its('can_purchase?')   { should be_false }
        its('can_refresh?')    { should be_true }
        its('can_unpurchase?') { should be_true }

        it 'unpurchases number' do
          expect { subject.unpurchase! }.not_to raise_error
        end
        it 'refreshes number' do
          pending { expect { subject.refresh! }.not_to raise_error }
        end
        it 'transitions to inactive state after unpurchasing' do
          expect { subject.unpurchase! }.to change(subject, :workflow_state).from('active').to('inactive')
        end
      end

    end # Valid number context
  
    context 'invalid number' do

      context 'when inactive (also new)' do
        subject { create :invalid_phone_number, organization: organization }
        it 'fails to purchase number' do
          expect { subject.purchase! }.to raise_error(Twilio::REST::RequestError)
        end
        it 'remains in inactivate state' do
          expect { subject.purchase! rescue subject }.not_to change(subject, :workflow_state).from('inactive')
        end
      end

    end # Invalid number context

    context 'unavailable number' do

      context 'when inactive (also new)' do
        subject { create :unavailable_phone_number, organization: organization }
        it 'fails to purchase number' do
          expect { subject.purchase! }.to raise_error(Twilio::REST::RequestError)
        end
        it 'remains in inactivate state' do
          expect { subject.purchase! rescue subject }.not_to change(subject, :workflow_state).from('inactive')
        end
      end

    end # Invalid number context

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
    
end
