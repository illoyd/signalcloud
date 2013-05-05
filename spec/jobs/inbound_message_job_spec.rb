require 'spec_helper'

describe InboundMessageJob, :vcr do
  
  let(:account)          { create(:account, :master_twilio) }
  let(:phone_book)  { create(:phone_book, account: account) }
  let(:stencil)        { create(:stencil, account: account, phone_book: phone_book) }
  let(:phone_number)     { create(:us_phone_number, account: account) }
  let(:customer_number)  { Twilio::VALID_NUMBER }

#   before(:each) { Message.destroy_all(twilio_sid: 'SM5e27df39904bc98686355dd7ec98f8a9') }
  
  def construct_inbound_payload( options={} )
    options.reverse_merge({
      'SmsSid' => 'SMe7a99c10b98ee37aa680ee0617c76d21',
      'AccountSid' => ENV['TWILIO_TEST_ACCOUNT_SID'],
      'From' => Twilio::VALID_NUMBER,
      'To' => Twilio::VALID_NUMBER,
      'Body' => 'Hello!'
    })
  end
  
  describe '#normalize_provider_update' do
    let(:payload) { construct_inbound_payload( 'To' => Twilio::VALID_NUMBER, 'From' => Twilio::INVALID_NUMBER ) }
    subject { InboundMessageJob.new(payload) }
    its(:normalize_provider_update) { should be_a(HashWithIndifferentAccess) }
    [ :to, :sms_sid, :account_sid, :from, :body ].each do |key|
      its(:normalize_provider_update) { should have_key key }
    end
  end
  
  describe '#normalize_provider_update!' do
    let(:payload) { construct_inbound_payload( 'To' => Twilio::VALID_NUMBER, 'From' => Twilio::INVALID_NUMBER ) }
    let(:normalized_payload) { subject.normalize_provider_update }
    subject { InboundMessageJob.new(payload) }
    it 'replaces existing provider_update' do
      expect{ subject.normalize_provider_update! }.to change{subject.provider_update}.to(normalized_payload)
    end
    it 'makes provider_update indifferent' do
      subject.normalize_provider_update!
      subject.provider_update.should be_a HashWithIndifferentAccess
    end
  end
  
  describe '#internal_phone_number' do
    let(:conversation)        { create(:conversation, :challenge_sent, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
    let(:payload) { construct_inbound_payload( 'To' => conversation.from_number, 'From' => conversation.to_number ) }
    subject { InboundMessageJob.new(payload) }
    
    its(:internal_phone_number) { should be_a PhoneNumber }
    its('internal_phone_number.id') { should == phone_number.id }
    its('internal_phone_number.number') { should == phone_number.number }
  end
  
  describe '#perform' do

    context 'when unsolicited (no matching conversation)' do
      let(:payload) { construct_inbound_payload( 'To' => phone_number.number, 'From' => customer_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_conversations) { should be_empty }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
#       it 'queues unsolicited message job' do
#         expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#       end
    end
    
    context 'when replying to open conversation' do
      let(:conversation)  { create(:conversation, :challenge_sent, :with_webhook_uri, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
      let(:payload) { construct_inbound_payload( 'To' => conversation.from_number, 'From' => conversation.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_conversations) { should have(1).item }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'queues response message and webhook jobs' do
        expect { subject.perform }.to change{Delayed::Job.count}.by(2)
      end
    end
    
    context 'when replying to multiple open conversation' do
      let(:conversationA)  { create(:conversation, :challenge_sent, :with_webhook_uri, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
      let(:conversationB)  { create(:conversation, :challenge_sent, :with_webhook_uri, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
      let(:conversationC)  { create(:conversation, :challenge_sent, :with_webhook_uri, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
      let(:conversations)  { [ conversationC, conversationA, conversationB ] }
      let(:payload)  { construct_inbound_payload( 'To' => conversations.first.from_number, 'From' => conversations.first.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_conversations) { should have(3).items }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'closes one conversation' do
        expect { subject.perform }.to change{subject.find_open_conversations.count}.by(-1)
      end
      it 'queues response message and webhook jobs' do
        expect { subject.perform }.to change{Delayed::Job.count}.by(2)
      end
    end
    
    context 'when replying to expired conversation' do
      let(:conversation)  { create(:conversation, :challenge_sent, :expired, stencil: stencil, expires_at: 180.seconds.ago, from_number: phone_number.number, to_number: customer_number) }
      let(:payload) { construct_inbound_payload( 'To' => conversation.from_number, 'From' => conversation.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_conversations) { should be_empty }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
#       it 'queues unsolicited message job' do
#         expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#       end
    end
    
    [ :confirmed, :denied, :failed ].each do |status|
      context "when replying to #{status.to_s} but not sent conversation" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, status, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => conversation.from_number, 'From' => conversation.to_number ) }
        subject { InboundMessageJob.new(payload) }

        its(:find_open_conversations) { should be_empty }
        its(:internal_phone_number) { should_not be_nil }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
#         it 'queues unsolicited message job' do
#           expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#         end
      end
      context "when replying to #{status.to_s} and sent conversation" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, status, :reply_sent, stencil: stencil, from_number: phone_number.number, to_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => conversation.from_number, 'From' => conversation.to_number ) }
        subject { InboundMessageJob.new(payload) }

        its(:find_open_conversations) { should be_empty }
        its(:internal_phone_number) { should_not be_nil }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
#         it 'queues unsolicited message job' do
#           expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#         end
      end
    end
    
  end #perform
  
end
