# encoding: UTF-8
require 'spec_helper'

describe Message, :vcr, :type => :model do
  
  # Helper: Build a random string for standard SMS
  def random_sms_string(length)
    charset_length = Message::SMS_CHARSET_LIST.length
    (1..length).map{ Message::SMS_CHARSET_LIST[rand(charset_length)] }.join('')
  end
  
  # Validations
  describe 'validations' do
    before(:each) { 3.times { create :message, :with_random_twilio_sid, :with_provider_response } }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to validate_numericality_of(:cost) }
  end
  
  describe '.is_sms_charset?' do
    context 'when in SMS charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "recognises #{length}-sized message" do
          expect(Message.is_sms_charset?(random_sms_string(length))).to be_truthy
        end
      end
    end
    context 'when using unicode charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "does not recognise #{length}-sized message" do
          expect(Message.is_sms_charset?(random_unicode_string(length))).to be_falsey
        end
      end
    end
  end
  
  describe '.select_sms_chunk_size' do
    context 'when in SMS charset' do
      [ 1, 8, 65, 159, 160, 161, 500 ].each do |length|
        it "recognises #{length}-sized message chunk size is 160" do
          expect(Message.select_message_chunk_size(random_sms_string(length))).to eq(160)
        end
      end
    end
    context 'when using unicode charset' do
      [ 1, 8, 69, 70, 71, 150, 500 ].each do |length|
        it "does not recognise #{length}-sized chunk size is 70" do
          expect(Message.select_message_chunk_size(random_unicode_string(length))).to eq(70)
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
#         expect { subject.update_costs }.not_to change(subject, :provider_cost)
#       end
#       it 'does not change .our_cost' do
#         expect { subject.update_costs }.not_to change(subject, :our_cost)
#       end
#     end
# 
#   end

  describe '#is_challenge? and #is_reply?' do
    context 'when challenge message' do
      subject { build :challenge_message }

      describe '#is_challenge?' do
        subject { super().is_challenge? }
        it { is_expected.to be_truthy }
      end

      describe '#is_reply?' do
        subject { super().is_reply? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when reply message' do
      subject { build :reply_message }

      describe '#is_challenge?' do
        subject { super().is_challenge? }
        it { is_expected.to be_falsey }
      end

      describe '#is_reply?' do
        subject { super().is_reply? }
        it { is_expected.to be_truthy }
      end
    end
    context 'when neither challenge nor reply message' do
      subject { build :message, message_kind: nil }

      describe '#is_challenge?' do
        subject { super().is_challenge? }
        it { is_expected.to be_falsey }
      end

      describe '#is_reply?' do
        subject { super().is_reply? }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#provider_response" do
    let(:provider_response) { { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access }
    context 'when provider_response is set' do
      subject { build :message, provider_response: provider_response }

      describe '#encrypted_provider_response' do
        subject { super().encrypted_provider_response }
        it { is_expected.not_to be_nil }
      end

      describe '#provider_response' do
        subject { super().provider_response }
        it { is_expected.not_to be_nil }
      end

      describe '#provider_response' do
        subject { super().provider_response }
        it { is_expected.to eq(provider_response) }
      end
    end
    context 'when provider_response is not set' do
      subject { build :message, provider_response: nil }

      describe '#encrypted_provider_response' do
        subject { super().encrypted_provider_response }
        it { is_expected.to be_nil }
      end

      describe '#provider_response' do
        subject { super().provider_response }
        it { is_expected.to be_nil }
      end
    end
  end
  
  describe '#deliver!' do
    let(:organization) { create :organization, :with_mock_comms, :with_sid_and_token }
    let(:phone_number) { create :valid_phone_number, :with_gateway, organization: organization }
    let(:phone_book)   { create :phone_book, organization: organization }
    let(:stencil)      { create :stencil, organization: organization, phone_book: phone_book }
    let(:conversation) { create :conversation, :real, stencil: stencil }
    let(:phone_book_entry) { create :phone_book_entry, phone_number: phone_number, phone_book: phone_book }
    before { phone_book_entry }

    context 'when properly configured' do
      subject { create :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER, body: 'Hello!' }
      it 'does not raise error' do
        expect { subject.deliver! }.not_to raise_error
      end
      it 'sets twilio sms sid' do
        expect { subject.deliver! }.to change{subject.provider_sid}.from(nil)
      end
      it 'sets provider_response' do
        expect { subject.deliver! }.to change{subject.provider_response}.from(nil)
      end
      it 'sets workflow_state' do
        expect { subject.deliver! }.to change{subject.workflow_state}.from('draft').to('sending')
      end
    end

    context 'when missing TO' do
      subject { create :message, conversation: conversation, to_number: nil, from_number: Twilio::VALID_NUMBER, body: 'Hello!' }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::InvalidToNumberMessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.not_to change{subject.provider_response}
      end
    end

    context 'when missing FROM' do
      subject { create :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: nil, body: 'Hello!' }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::InvalidFromNumberMessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.not_to change{subject.provider_response}
      end
    end

    context 'when missing BODY' do
      subject { create :message, conversation: conversation, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER, body: nil }
      it "raises error" do
        expect{ subject.deliver! }.to raise_error( SignalCloud::InvalidBodyMessageSendingError )
      end
      it 'does not change provider response' do
        expect{ subject.deliver! rescue nil }.not_to change{subject.provider_response}
      end
    end
  end
  
end
