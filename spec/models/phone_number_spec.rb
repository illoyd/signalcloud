require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber, :vcr, :type => :model do

  let(:organization) { create :organization, :test_twilio, :with_sid_and_token }
  let(:comm_gateway) { organization.communication_gateway_for(:twilio) }
  
  # Manage all validations
  describe "validations" do
    before { 3.times { create :phone_number, organization: organization, communication_gateway: comm_gateway } }

    # Belong-To
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:communication_gateway) }

    # Have-Many
    [ :phone_books, :phone_book_entries ].each do |entry|
      it { is_expected.to have_many(entry) }
    end
    
    # Validate presence
    [ :organization, :number, :communication_gateway ].each do |entry|
      it { is_expected.to validate_presence_of(entry) }
    end
    
    # Validate numericality
    it { is_expected.to validate_numericality_of(:cost) }
  end
  
  describe '.find_by_number' do
    let(:valid_number)   { '+15551234567' }
    let(:unknown_number) { '+18001234567' }
    let(:phone_number)   { create :phone_number, number: valid_number, organization: organization, communication_gateway: comm_gateway }
    
    it 'finds valid number' do
      expect(PhoneNumber.find_by_number(phone_number.number)).to be_a( PhoneNumber )
    end
    
    it 'cannot find a plausible number' do
      expect(PhoneNumber.find_by_number(unknown_number)).to be_nil
    end
    
    it 'cannot find an implausible number' do
      expect( PhoneNumber.find_by_number('hello') ).to be_nil
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

        describe '#can_purchase?' do
          subject { super().can_purchase? }
          it { is_expected.to be_truthy }
        end

        describe '#can_refresh?' do
          subject { super().can_refresh? }
          it { is_expected.to be_falsey }
        end

        describe '#can_release?' do
          subject { super().can_release? }
          it { is_expected.to be_falsey }
        end

        it 'purchases number' do
          pending 'Swap out Twilio Gateway for generic'
          expect { subject.purchase! }.not_to raise_error
        end
        it 'transitions to active state after purchasing' do
          pending 'Swap out Twilio Gateway for generic'
          expect { subject.purchase! }.to change(subject, :workflow_state).from('inactive').to('active')
        end
      end
      
      context 'when active' do
        subject { create :valid_phone_number, :active, :with_fixed_twilio_sid, organization: organization, communication_gateway: comm_gateway }

        describe '#can_purchase?' do
          subject { super().can_purchase? }
          it { is_expected.to be_falsey }
        end

        describe '#can_refresh?' do
          subject { super().can_refresh? }
          it { is_expected.to be_truthy }
        end

        describe '#can_release?' do
          subject { super().can_release? }
          it { is_expected.to be_truthy }
        end

        it 'releases number' do
          pending 'Swap out Twilio Gateway for generic'
          expect { subject.release! }.not_to raise_error
        end
        it 'refreshes number' do
          pending 'Swap out Twilio Gateway for generic'
          expect { subject.refresh! }.not_to raise_error
        end
        it 'transitions to inactive state after unpurchasing' do
          pending 'Swap out Twilio Gateway for generic'
          expect { subject.release! }.to change(subject, :workflow_state).from('active').to('inactive')
        end
      end

    end # Valid number context
  
    context 'invalid number' do

      context 'when inactive (also new)' do
        subject { create :invalid_phone_number, organization: organization, communication_gateway: comm_gateway }
        it 'fails to purchase number' do
          pending 'Swap with Mock Gateway'
          expect { subject.purchase! }.to raise_error(Twilio::REST::RequestError)
        end
        it 'remains in inactivate state' do
          expect { subject.purchase! rescue subject }.not_to change(subject, :workflow_state).from('inactive')
        end
      end

    end # Invalid number context

    context 'unavailable number' do

      context 'when inactive (also new)' do
        subject { create :unavailable_phone_number, organization: organization, communication_gateway: comm_gateway }
        it 'fails to purchase number' do
          pending 'Swap with Mock Gateway'
          expect { subject.purchase! }.to raise_error(Twilio::REST::RequestError)
        end
        it 'remains in inactivate state' do
          expect { subject.purchase! rescue subject }.not_to change(subject, :workflow_state).from('inactive')
        end
      end

    end # Unavailable number context

  end
  
  describe 'unsolicited call helpers' do
    context 'when action is REJECT' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::REJECT) }

      describe '#should_reject_unsolicited_call?' do
        subject { super().should_reject_unsolicited_call? }
        it { is_expected.to be_truthy }
      end

      describe '#should_play_busy_for_unsolicited_call?' do
        subject { super().should_play_busy_for_unsolicited_call? }
        it { is_expected.to be_falsey }
      end

      describe '#should_reply_to_unsolicited_call?' do
        subject { super().should_reply_to_unsolicited_call? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when action is BUSY' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::BUSY) }

      describe '#should_reject_unsolicited_call?' do
        subject { super().should_reject_unsolicited_call? }
        it { is_expected.to be_falsey }
      end

      describe '#should_play_busy_for_unsolicited_call?' do
        subject { super().should_play_busy_for_unsolicited_call? }
        it { is_expected.to be_truthy }
      end

      describe '#should_reply_to_unsolicited_call?' do
        subject { super().should_reply_to_unsolicited_call? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when action is REPLY' do
      subject { build(:phone_number, unsolicited_call_action: PhoneNumber::REPLY) }

      describe '#should_reject_unsolicited_call?' do
        subject { super().should_reject_unsolicited_call? }
        it { is_expected.to be_falsey }
      end

      describe '#should_play_busy_for_unsolicited_call?' do
        subject { super().should_play_busy_for_unsolicited_call? }
        it { is_expected.to be_falsey }
      end

      describe '#should_reply_to_unsolicited_call?' do
        subject { super().should_reply_to_unsolicited_call? }
        it { is_expected.to be_truthy }
      end
    end
  end
  
  describe 'unsolicited sms helpers' do
    context 'when action is IGNORE' do
      subject { build(:phone_number, unsolicited_sms_action: PhoneNumber::IGNORE) }

      describe '#should_ignore_unsolicited_sms?' do
        subject { super().should_ignore_unsolicited_sms? }
        it { is_expected.to be_truthy }
      end

      describe '#should_reply_to_unsolicited_sms?' do
        subject { super().should_reply_to_unsolicited_sms? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when action is REPLY' do
      subject { build(:phone_number, unsolicited_sms_action: PhoneNumber::REPLY) }

      describe '#should_ignore_unsolicited_sms?' do
        subject { super().should_ignore_unsolicited_sms? }
        it { is_expected.to be_falsey }
      end

      describe '#should_reply_to_unsolicited_sms?' do
        subject { super().should_reply_to_unsolicited_sms? }
        it { is_expected.to be_truthy }
      end
    end
  end
    
end
