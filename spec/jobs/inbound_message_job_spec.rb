require 'spec_helper'

describe InboundMessageJob, :vcr do
  let(:sms_sid )        { 'SM7104b239862b9006bd360a3d5f285f2e' }
  let(:organization)    { create(:organization, :master_twilio) }
  let(:phone_book)      { create(:phone_book, organization: organization) }
  let(:stencil)         { create(:stencil, organization: organization, phone_book: phone_book) }
  let(:phone_number)    { create(:phone_number, organization: organization) }
  let(:customer_number) { Twilio::VALID_NUMBER }

  def construct_inbound_payload( options={} )
    options.reverse_merge({
      'SmsSid' => sms_sid,
      'AccountSid' => ENV['TWILIO_TEST_ACCOUNT_SID'],
      'From' => Twilio::VALID_NUMBER,
      'To' => Twilio::VALID_NUMBER,
      'Body' => 'Hello!',
      'SmsStatus' => 'received'
    })
  end
  
  describe '#internal_phone_number' do
    let(:conversation) { create(:conversation, :mock, :challenge_sent, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
    let(:payload)      { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number ) }
    before             { subject.perform(payload) }
    
    its(:internal_phone_number) { should be_a PhoneNumber }
    its('internal_phone_number.id') { should == phone_number.id }
    its('internal_phone_number.number') { should == phone_number.number }
  end
  
  describe '#perform' do

    context 'when unsolicited (no matching conversation)' do
      let(:payload) { construct_inbound_payload( 'To' => phone_number.number, 'From' => customer_number ) }

      it 'does not raise an error' do
        expect{ subject.perform(payload) }.not_to raise_error
      end
      it 'does not find an open conversation' do
        subject.provider_update = payload
        subject.find_open_conversations.should be_empty
      end
      it 'has an internal phone number' do
        subject.provider_update = payload
        subject.internal_phone_number.should_not be_nil        
      end
    end
    
    context 'when replying to open conversation' do
      let(:conversation) { create(:conversation, :mock, :challenge_sent, :with_webhook_uri, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
      let(:payload)      { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number ) }
      
      it 'has an internal phone number' do
        subject.provider_update = payload
        subject.internal_phone_number.should_not be_nil        
      end
      it 'finds an open conversation' do
        subject.provider_update = payload
        subject.find_open_conversations.should have(1).item
      end

      context 'with a confirmed response' do
        let(:payload)    { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number, 'Body' => conversation.expected_confirmed_answer ) }
        it 'does not raise an error' do
          expect{ subject.perform(payload) }.not_to raise_error
        end
        it 'transitions conversation to confirmed' do
          expect{ subject.perform(payload) }.to change{ conversation.reload.workflow_state }.to('confirming')
        end
      end

      context 'with a denied response' do
        let(:payload)    { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number, 'Body' => conversation.expected_denied_answer ) }
        it 'does not raise an error' do
          expect{ subject.perform(payload) }.not_to raise_error
        end
        it 'transitions conversation to denied' do
          expect{ subject.perform(payload) }.to change{ conversation.reload.workflow_state }.to('denying')
        end
      end

      context 'with a failed response' do
        let(:payload)    { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number, 'Body' => 'walrus' ) }
        it 'does not raise an error' do
          expect{ subject.perform(payload) }.not_to raise_error
        end
        it 'transitions conversation to failed' do
          expect{ subject.perform(payload) }.to change{ conversation.reload.workflow_state }.to('failing')
        end
      end
    end
    
    context 'when replying to multiple open conversation' do
      let(:conversationA)  { create(:conversation, :mock, :challenge_sent, :with_webhook_uri, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
      let(:conversationB)  { create(:conversation, :mock, :challenge_sent, :with_webhook_uri, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
      let(:conversationC)  { create(:conversation, :mock, :challenge_sent, :with_webhook_uri, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
      let(:conversations)  { [ conversationC, conversationA, conversationB ] }
      let(:payload)  { construct_inbound_payload( 'To' => conversations.first.internal_number, 'From' => conversations.first.customer_number ) }

      it 'finds three open conversations' do
        subject.provider_update = payload
        subject.find_open_conversations.should have(3).items
      end
      it 'has an internal phone number' do
        subject.provider_update = payload
        subject.internal_phone_number.should_not be_nil        
      end
      it 'does not raise an error' do
        expect{ subject.perform(payload) }.not_to raise_error
      end
      it 'closes one conversation' do
        subject.provider_update = payload
        expect { subject.perform(payload) }.to change{subject.find_open_conversations.count}.by(-1)
      end
    end
    
    context 'when replying to expired conversation' do
      let(:conversation)  { create(:conversation, :mock, :challenge_sent, :expired, stencil: stencil, expires_at: 180.seconds.ago, internal_number: phone_number.number, customer_number: customer_number) }
      let(:payload) { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number ) }

      it 'does not find an open conversation' do
        subject.provider_update = payload
        subject.find_open_conversations.should be_empty
      end
      it 'sends unsolicited message' do
        expect{ subject.perform(payload) }.to change( phone_number.unsolicited_messages, :count ).by(1)
      end
    end
    
    [ :confirmed, :denied, :failed ].each do |status|
      context "when replying to #{status.to_s} but not sent conversation" do
        let(:conversation)  { create(:conversation, :mock, :challenge_sent, :response_received, status, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number ) }

        it 'does not find an open conversation' do
          subject.provider_update = payload
          subject.find_open_conversations.should be_empty
        end
        it 'sends unsolicited message' do
          expect{ subject.perform(payload) }.to change( phone_number.unsolicited_messages, :count ).by(1)
        end
      end
      context "when replying to #{status.to_s} and sent conversation" do
        let(:conversation)  { create(:conversation, :mock, :challenge_sent, :response_received, status, :reply_sent, stencil: stencil, internal_number: phone_number.number, customer_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => conversation.internal_number, 'From' => conversation.customer_number ) }

        it 'does not find an open conversation' do
          subject.provider_update = payload
          subject.find_open_conversations.should be_empty
        end
        it 'sends unsolicited message' do
          expect{ subject.perform(payload) }.to change( phone_number.unsolicited_messages, :count ).by(1)
        end
      end
    end
    
  end #perform
  
end
