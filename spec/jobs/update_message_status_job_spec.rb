require 'spec_helper'

describe UpdateMessageStatusJob, :vcr do
  let(:sms_sid) { 'SMf7b41f7c4091865e1ba41b9d9a27833d' }
  
  def create_message_update_payload( message, body=nil, reply=false, others={} )
    body = message.conversation.question if body.nil?
    return {
      'AccountSid' => message.conversation.organization.twilio_account_sid,
      'SmsSid' =>     message.twilio_sid,
      'ApiVersion' => '2010-04-01',
      'From' =>       reply ? message.conversation.to_number : message.conversation.from_number,
      'To' =>	        reply ? message.conversation.from_number : message.conversation.to_number,
      'Body' =>       body,
      'SmsStatus' =>	'sent'
    }.merge(others)
  end
  
  def create_extended_message_update_payload( message, body=nil, reply=false )
    return create_message_update_payload( message, body, reply, {
      'Price' =>  '-0.04',
      'DateSent' => 30.minutes.ago.rfc2822
    })
  end

  describe '#perform' do
    let(:organization)    { create :organization, :master_twilio }
    let(:stencil)         { create :stencil, organization: organization }
    let(:date_sent)       { 15.minutes.ago.to_time.round }
    let(:payload)         { create_message_update_payload message, nil, false, { 'Price' => -0.04, 'DateSent' => date_sent.rfc2822 } }
    let(:queued_payload)  { create_message_update_payload message, nil, false, { 'SmsStatus' => 'queued', 'Price' => nil, 'DateSent' => nil } }
    let(:sending_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sending', 'Price' => nil, 'DateSent' => nil } }
    let(:sent_payload)    { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sent', 'Price' => '-0.04', 'DateSent' => date_sent.rfc2822 } }
    
    context 'when challenge has been sent' do
      let(:conversation) { create :conversation, stencil: stencil }
      let(:message)      { create(:challenge_message, conversation: conversation, twilio_sid: sms_sid) }

      context 'and message is queued' do
        let(:payload) { queued_payload }
        it 'updates message payload' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::QUEUED)
        end
        it 'does not update message sent_at' do
          expect { subject.perform( payload ) }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'updates conversation status' do
          expect { subject.perform( payload ) }.to change{message.reload.conversation(true).status}.to(Conversation::QUEUED)
        end
        it 'does not create a ledger entry' do
          expect { subject.perform( payload ) }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sending' do
        let(:payload) { sending_payload }
        it 'updates message callback' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::SENDING)
        end
        it 'does not update message sent_at' do
          expect { subject.perform( payload ) }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'updates conversation status' do
          expect { subject.perform( payload ) }.to change{message.reload.conversation(true).status}.to(Conversation::QUEUED)
        end
        it 'does not create a ledger entry' do
          expect { subject.perform( payload ) }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sent' do
        let(:payload) { sent_payload }
        it 'updates message payload' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::SENT)
        end
        it 'updates message sent_at' do
          subject.perform( payload )
          message.reload.sent_at.to_time.round.should == date_sent.round
        end
        it 'updates conversation status' do
          expect { subject.perform( payload ) }.to change{message.reload.conversation(true).status}.to(Conversation::CHALLENGE_SENT)
        end
        it 'creates a ledger entry' do
          subject.perform( payload )
          message.reload.ledger_entry.should_not be_nil
        end
        it 'settles ledger entry' do
          expect { subject.perform( payload ) }.to change{message.reload.ledger_entry(true).try(:settled_at)}.from(nil).to(date_sent)
        end
        it 'updates ledger entry costs' do
          expect { subject.perform( payload ) }.to change{message.reload.ledger_entry(true).try(:value)} #.to(message.reload.cost)
        end
      end
    end
    
    context 'when reply has been sent' do
      let(:conversation)  { create :conversation, :confirmed, stencil: stencil }
      let(:message) { create(:reply_message, conversation: conversation, twilio_sid: sms_sid) }

      context 'and message is queued' do
        let(:payload) { queued_payload }
        it 'updates message payload' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::QUEUED)
        end
        it 'does not update message sent_at' do
          expect { subject.perform( payload ) }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'does not change conversation status' do
          expect { subject.perform( payload ) }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'does not create a ledger entry' do
          expect { subject.perform( payload ) }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sending' do
        let(:payload) { sending_payload }
        it 'updates message callback' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::SENDING)
        end
        it 'does not update message sent_at' do
          expect { subject.perform( payload ) }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'does not change conversation status' do
          expect { subject.perform( payload ) }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'does not create a ledger entry' do
          expect { subject.perform( payload ) }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sent' do
        let(:payload) { sent_payload }
        it 'updates message payload' do
          expect { subject.perform( payload ) }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { subject.perform( payload ) }.to change{message.reload.status}.to(Message::SENT)
        end
        it 'updates message sent_at' do
          subject.perform( payload )
          message.reload.sent_at.to_time.round.should == date_sent.round
        end
        it 'does not change conversation status' do
          expect { subject.perform( payload ) }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'creates a ledger entry' do
          subject.perform( payload )
          message.reload.ledger_entry.should_not be_nil
        end
        it 'settles ledger entry' do
          expect { subject.perform( payload ) }.to change{message.reload.ledger_entry(true).try(:settled_at)}.from(nil).to(date_sent)
        end
        it 'updates ledger entry costs' do
          expect { subject.perform( payload ) }.to change{message.reload.ledger_entry(true).try(:value)} #.to(message.reload.cost)
        end
      end
    end

  end

end
