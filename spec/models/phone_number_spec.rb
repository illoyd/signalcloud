require 'spec_helper'

# Constants for testing
UNAVAILABLE_NUMBER = '+15005550000'
INVALID_NUMBER = '+15005550001'
AVAILABLE_NUMBER = '+15005550006'  
UNAVAILABLE_AREACODE = '533'
AVAILABLE_AREACODE = '500'

describe PhoneNumber, :vcr do
  
  it_behaves_like 'a costable item', :phone_number

  let(:organization) { create :organization, :test_twilio, :with_sid_and_token }
  
  # Manage all validations
  describe "validations" do
    before(:all) { 3.times { create :phone_number } }

    # Allow mass assignment
    [ :number, :twilio_phone_number_sid, :organization_id, :our_cost, :provider_cost, :unsolicited_sms_action, :unsolicited_sms_message, :unsolicited_call_action, :unsolicited_call_message, :unsolicited_call_language, :unsolicited_call_voice ].each do |entry|
      it { should allow_mass_assignment_of(entry) }
    end
    
    # Belong-To
    it { should belong_to(:organization) }

    # Have-Many
    [ :phone_books, :phone_book_entries ].each do |entry|
      it { should have_many(entry) }
    end
    
    # Validate presence
    [ :organization, :number ].each do |entry|
      it { should validate_presence_of(entry) }
    end
    
    # Validate numericality
    [ :organization_id, :our_cost, :provider_cost ].each do |entry|
      it { should validate_numericality_of(entry) }
    end
        
    # Uniqueness
    pending 'Needs updated validate_uniqueness_of test' do
      it { should validate_uniqueness_of(:twilio_phone_number_sid) }
    end
    
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

  # Manage buying
  describe "#purchase" do
  
    context 'valid number' do

      context 'when inactive' do
        subject { create :valid_phone_number, organization: organization }
        it 'can be purchased' do
          subject.can_purchase?.should be_true
        end
        it 'cannot be refreshed' do
          subject.can_refresh?.should be_false
        end
        it 'cannot be unpurchased' do
          subject.can_unpurchase?.should be_false
        end
        it 'purchases number' do
          expect { subject.purchase! }.not_to raise_error
        end
        
        it 'transitions to active state after purchasing' do
          expect { subject.purchase! }.to change(subject, :workflow_state).from('inactive').to('active')
        end
  
        it 'enqueues a purchase number command' do
          expect { subject.enqueue_purchase! }.not_to raise_error
        end
        it 'transitions to pending state after enqueuing purchase' do
          expect { subject.enqueue_purchase! }.to change(subject, :workflow_state).from('inactive').to('pending_purchase')
        end
      end
      
      context 'when active' do
        subject { create :valid_phone_number, :active, :with_fixed_twilio_sid, organization: organization }
        it 'cannot be purchased' do
          subject.can_purchase?.should be_false
        end
        it 'can be refreshed' do
          subject.can_refresh?.should be_true
        end
        it 'can be unpurchased' do
          subject.can_refresh?.should be_true
        end

        it 'unpurchases number' do
          pending 'Twilio does not allow testing Phone Number Instance deletions' do
            expect { subject.unpurchase! }.not_to raise_error
          end
        end
        it 'refreshes number' do
          pending 'Twilio does not allow testing Phone Number Instance updates' do
            expect { subject.refresh! }.not_to raise_error
          end
        end
  
        it 'transitions to inactive state after unpurchasing' do
          pending 'Twilio does not allow testing Phone Number Instance deletion' do
            expect { subject.unpurchase! }.to change(subject, :workflow_state).from('active').to('inactive')
          end
        end
  
        it 'enqueues an unpurchase number command' do
          expect { subject.enqueue_unpurchase! }.not_to raise_error
        end
        it 'transitions to pending state after enqueuing unpurchase' do
          expect { subject.enqueue_unpurchase! }.to change(subject, :workflow_state).from('active').to('pending_unpurchase')
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
  
end
