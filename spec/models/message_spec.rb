# encoding: UTF-8
require 'spec_helper'

describe Message, :vcr do
  
  it_behaves_like 'a costable item', :message

  # Helper: Build a random string for standard SMS
  def random_sms_string(length)
    charset_length = Message::SMS_CHARSET_LIST.length
    (1..length).map{ Message::SMS_CHARSET_LIST[rand(charset_length)] }.join('')
  end
  
  # Validations
  describe 'validations' do
    before(:all) { 3.times { create :message, :with_random_twilio_sid, :with_provider_response } }
    [ :our_cost, :provider_cost, :conversation_id, :provider_response, :provider_update, :twilio_sid ].each do |attribute| 
      it { should allow_mass_assignment_of attribute }
    end
    it { should belong_to(:conversation) }
    it { should have_one(:ledger_entry) }
    it { should validate_presence_of(:conversation_id) }
    it { should ensure_length_of(:twilio_sid).is_equal_to(Twilio::SID_LENGTH) }
    it { should validate_numericality_of(:our_cost) }
    it { should validate_numericality_of(:provider_cost) }
    it { should validate_uniqueness_of(:twilio_sid) }
  end
  
  describe '.is_sms_charset?' do
    context 'when in SMS charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "recognises #{length}-sized message" do
          Message.is_sms_charset?(random_sms_string(length)).should be_true
        end
      end
    end
    context 'when using unicode charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "does not recognise #{length}-sized message" do
          Message.is_sms_charset?(random_unicode_string(length)).should be_false
        end
      end
    end
  end
  
  describe '.select_sms_chunk_size' do
    context 'when in SMS charset' do
      [ 1, 8, 65, 159, 160, 161, 500 ].each do |length|
        it "recognises #{length}-sized message chunk size is 160" do
          Message.select_message_chunk_size(random_sms_string(length)).should == 160
        end
      end
    end
    context 'when using unicode charset' do
      [ 1, 8, 69, 70, 71, 150, 500 ].each do |length|
        it "does not recognise #{length}-sized chunk size is 70" do
          Message.select_message_chunk_size(random_unicode_string(length)).should == 70
        end
      end
    end
  end
  
#   describe '.update_costs' do
# 
#     context 'when costs not set' do
#       subject { create :message }
#       before(:each) { 
#         subject.conversation.stencil.organization.account_plan = create(:ridiculous_account_plan)
#         subject.provider_response = subject.provider_response.with_indifferent_access.merge(price: -1.23)
#       }
#       its(:provider_cost) { should be_nil }
#       its(:our_cost) { should be_nil }
#       its(:provider_price) { should_not be_nil }
#       its(:'has_provider_price?') { should be_true }
#       it 'changes .provider_cost' do
#         expect { subject.update_costs }.to change(subject, :provider_cost)
#       end
#       it 'changes .our_cost' do
#         expect { subject.update_costs }.to change(subject, :our_cost)
#       end
#     end
# 
#     context 'when costs already set' do
#       subject { create :message, :settled }
#       before(:each) { 
#         subject.conversation.stencil.organization.account_plan = create(:ridiculous_account_plan)
#         subject.provider_response = subject.provider_response.with_indifferent_access.merge(price: -1.23)
#       }
#       its(:provider_cost) { should_not be_nil }
#       its(:our_cost) { should_not be_nil }
#       its(:provider_price) { should_not be_nil }
#       its(:'has_provider_price?') { should be_true }
#       it 'does not change .provider_cost' do
#         expect { subject.update_costs }.to_not change(subject, :provider_cost)
#       end
#       it 'does not change .our_cost' do
#         expect { subject.update_costs }.to_not change(subject, :our_cost)
#       end
#     end
# 
#   end

  describe '#is_challenge? and #is_reply?' do
    context 'when challenge message' do
      subject { build :challenge_message }
      its(:'is_challenge?') { should be_true }
      its(:'is_reply?') { should be_false }
    end
    context 'when reply message' do
      subject { build :reply_message }
      its(:'is_challenge?') { should be_false }
      its(:'is_reply?') { should be_true }
    end
    context 'when neither challenge nor reply message' do
      subject { build :message, message_kind: nil }
      its(:'is_challenge?') { should be_false }
      its(:'is_reply?') { should be_false }
    end
  end

  describe "#provider_response" do
    let(:provider_response) { { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access }
    context 'when provider_response is set' do
      subject { build :message, provider_response: provider_response }
      its(:encrypted_provider_response) { should_not be_nil }
      its(:provider_response) { should_not be_nil }
      its(:provider_response) { should eq(provider_response) }
    end
    context 'when provider_response is not set' do
      subject { build :message, provider_response: nil }
      its(:encrypted_provider_response) { should be_nil }
      its(:provider_response) { should be_nil }
    end
  end
  
#   describe "#cached_payload" do
#     it "should encrypt and decrypt nicely" do
#       # Prepare an expected payload
#       expected_payload = { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access
#       
#       # Next, create a new message without a payload; the cache should be nil
#       message = Message.new()
#       message.cached_payload.should be_nil
#       
#       # Add the payload, then re-try - they should not be nil
#       message.payload = expected_payload
#       message.cached_payload.should_not be_nil
# 
#       # Ensure that payload is equal to its cache
#       message.cached_payload.should eq( message.payload )
#       message.cached_payload.should eq( expected_payload )
#     end
#   end

#   describe '#cost' do
#     [ [nil,nil], [nil,1], [1,nil], [1,1], [1,-1], [-1,1], [0.25,-0.32] ].each do |costs|
#       it "properly sums provider:#{costs.first} and our:#{costs.second}" do
#         msg = build :message, provider_cost: costs.first, our_cost: costs.second
#         msg.cost.should == costs.reject{ |entry| entry.nil? }.sum
#       end
#     end
#   end

  describe '#has_cost?' do
    context 'when both costs are present' do
      subject { build :message, provider_cost: -1.00, our_cost: -0.50 }
      its(:'has_cost?') { should be_true }
    end
    context 'when only provider_cost is present' do
      subject { build :message, provider_cost: -1.00, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end
    context 'when only our_cost is present' do
      subject { build :message, provider_cost: nil, our_cost: -0.50 }
      its(:'has_cost?') { should be_false }
    end
    context 'when both costs are not present' do
      subject { build :message, provider_cost: nil, our_cost: nil }
      its(:'has_cost?') { should be_false }
    end
  end
  
  describe '#provider_cost=' do
    context 'when cost is not nil' do
      subject { build :message, :with_random_twilio_sid, :with_provider_response }
      let(:provider_cost) { -1.00 }
      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(provider_cost)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }
      end
    end
    context 'when cost is nil' do
      subject { build :message, :with_random_twilio_sid, :with_provider_response, provider_cost: -1.00, our_cost: -0.50 }
      let(:provider_cost) { nil }
      it 'updates provider_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.provider_cost }.to(nil)
      end
      it 'updates our_cost' do
        expect{ subject.provider_cost = provider_cost }.to change{ subject.our_cost }.to(nil)
      end
    end
  end
  
  describe 'callbacks' do
    let(:provider_cost) { -0.01 }
    let(:provider_response) { { body: 'Hello!', to: '+12121234567', from: '+4561237890', status: 'queued' } }
    subject { build :message, :with_random_twilio_sid, :with_provider_response, body: provider_response[:body], to_number: provider_response[:to], from_number: provider_response[:from], provider_response: provider_response }

    context 'when price is set' do
      it 'creates a ledger entry' do
        subject.provider_cost = provider_cost
        expect{ subject.save! }.to change{subject.ledger_entry}.from(nil)
      end
      it 'sets ledger entry\'s value' do
        subject.provider_cost = provider_cost
        subject.save!
        subject.ledger_entry.value.should == subject.cost
      end
    end

    context 'when price is not set' do
      it 'does not create a ledger entry' do
        subject.provider_cost = nil
        expect{ subject.save! }.to_not change{subject.ledger_entry}.from(nil)
      end
    end

#     it 'should auto-save ledger entry' do
#       message = Message.new( payload: { body: 'Hello!', to: '+12121234567', from: '+4561237890' }, twilio_sid: 'XX' + SecureRandom.hex(16) )
#       message.conversation = conversations(:test_conversation)
#       message.organization.should_not be_nil
#       #expect{ message.save! }.to_not raise_error
#       
#       ledger_entry = message.build_ledger_entry( narrative: 'TEST' )
#       #ledger_entry.item = message
#       expect{ message.save! }.to_not raise_error
#       
#       ledger_entry.item_id.should eq( message.id )
#       ledger_entry.item_type.should eq( message.class.name.to_s )
#       ledger_entry.item.should eq( message )
# 
#       #ledger_entry.item.respond_to?(:organization).should == true
#       #ledger_entry.item.should_not be_nil
# 
#       expect{ ledger_entry.ensure_organization }.to_not raise_error      
#       ledger_entry.organization_id.should eq( message.organization.id )
#       
#       expect{ message.save! }.to_not raise_error
#     end
  end
  
#   describe "payload helpers" do
#     let(:expected_payload) { { body: 'Hello!', to: '+12121234567', from: '+4561237890', direction: 'api-in' }.with_indifferent_access }
#     subject { create :message, payload: expected_payload }
#     its(:body) { should == expected_payload[:body] }
#     its(:to_number) { should == expected_payload[:to] }
#     its(:from_number) { should == expected_payload[:from] }
#     its(:direction) { should == expected_payload[:direction] }
#   end
  
  describe '#deliver!' do
    let(:organization) { create :organization, :test_twilio, :with_sid_and_token }
    let(:phone_number) { create :valid_phone_number, organization: organization }
    let(:phone_book) { create :phone_book, organization: organization }
    let(:stencil) { create :stencil, organization: organization, phone_book: phone_book }
    let(:conversation) { create :conversation, stencil: stencil }
    let!(:phone_book_entry) { create :phone_book_entry, phone_number: phone_number, phone_book: phone_book }

    context 'when properly configured' do
      subject { build :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER, body: 'Hello!' }
      it 'does not raise error' do
        expect { subject.deliver! }.to_not raise_error
      end
      it 'sets twilio sms sid' do
        expect { subject.deliver! }.to change{subject.twilio_sid}.from(nil)
      end
      it 'sets provider_response' do
        expect { subject.deliver! }.to change{subject.provider_response}.from(nil)
      end
      it 'sets status' do
        expect { subject.deliver! }.to change{subject.status}.from(Message::PENDING)
      end
    end

    context 'when missing TO' do
      subject { build :message, conversation: conversation, to_number: nil, from_number: Twilio::VALID_NUMBER, body: 'Hello!' }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::MessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.to_not change{subject.provider_response}
      end
    end

    context 'when missing FROM' do
      subject { build :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: nil, body: 'Hello!' }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::MessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.to_not change{subject.provider_response}
      end
    end

    context 'when missing BODY' do
      subject { build :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER, body: nil }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::CriticalMessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.to_not change{subject.provider_response}
      end
    end
  end
  
end
