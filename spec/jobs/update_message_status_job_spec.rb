require 'spec_helper'

describe UpdateMessageStatusJob, :vcr do
  
  def create_message_update_payload( message, body=nil, reply=false, others={} )
    body = message.conversation.question if body.nil?
    {
      'AccountSid' => message.conversation.account.twilio_account_sid,
      'SmsSid' =>     message.twilio_sid,
      'ApiVersion' => '2010-04-01',
      'From' =>       reply ? message.conversation.to_number : message.conversation.from_number,
      'To' =>	        reply ? message.conversation.from_number : message.conversation.to_number,
      'Body' =>       body,
      'SmsStatus' =>	'sent'
    }.merge(others)
  end
  
  def create_extended_message_update_payload( message, body=nil, reply=false )
    return create_message_update_payload( message, body, reply ).merge!({
      'Price' =>  -0.04,
      'DateSent' => DateTime.now
    })
  end

  describe '.new' do
    it 'should create new' do
      expected_payload = { sms_sid: 'yyy', price: 0.04, sms_status: 'sending' }
      job = UpdateMessageStatusJob.new( expected_payload )
      job.callback_values.should eq( expected_payload )
    end
  end
  
  describe '#perform' do
    let(:date_sent) { 15.seconds.ago }
    let(:payload) { create_message_update_payload message, nil, false, { 'Price' => -0.04, 'DateSent' => date_sent } }
    let(:queued_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'queued', 'Price' => nil, 'DateSent' => nil } }
    let(:sending_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sending', 'Price' => nil, 'DateSent' => nil } }
    let(:sent_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sent', 'Price' => -0.04, 'DateSent' => date_sent } }
    
    context 'when challenge has been sent' do
      let(:message) { create(:challenge_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }

      context 'and message is queued' do
        let(:job) { UpdateMessageStatusJob.new queued_payload }
        it 'updates message payload' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::QUEUED)
        end
        it 'does not update message sent_at' do
          expect { job.perform }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'updates conversation status' do
          expect { job.perform }.to change{message.reload.conversation(true).status}.to(Conversation::QUEUED)
        end
        it 'does not create a ledger entry' do
          expect { job.perform }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sending' do
        let(:job) { UpdateMessageStatusJob.new sending_payload }
        it 'updates message callback' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::SENDING)
        end
        it 'does not update message sent_at' do
          expect { job.perform }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'updates conversation status' do
          expect { job.perform }.to change{message.reload.conversation(true).status}.to(Conversation::QUEUED)
        end
        it 'does not create a ledger entry' do
          expect { job.perform }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sent' do
        let(:job) { UpdateMessageStatusJob.new sent_payload }
        it 'updates message payload' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::SENT)
        end
        it 'updates message sent_at' do
          expect { job.perform }.to change{message.reload.sent_at}.from(nil).to(date_sent)
        end
        it 'updates conversation status' do
          expect { job.perform }.to change{message.reload.conversation(true).status}.to(Conversation::CHALLENGE_SENT)
        end
        it 'creates a ledger entry' do
          job.perform
          message.reload.ledger_entry.should_not be_nil
        end
        it 'settles ledger entry' do
          expect { job.perform }.to change{message.reload.ledger_entry(true).settled_at}.from(nil).to(date_sent)
        end
        it 'updates ledger entry costs' do
          expect { job.perform }.to change{message.reload.ledger_entry(true).value} #.to(message.reload.cost)
        end
      end
    end
    
    context 'when reply has been sent' do
      let(:conversation)  { create :conversation, :confirmed }
      let(:message) { create(:reply_message, conversation: conversation, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }

      context 'and message is queued' do
        let(:job) { UpdateMessageStatusJob.new queued_payload }
        it 'updates message payload' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::QUEUED)
        end
        it 'does not update message sent_at' do
          expect { job.perform }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'does not change conversation status' do
          expect { job.perform }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'does not create a ledger entry' do
          expect { job.perform }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sending' do
        let(:job) { UpdateMessageStatusJob.new sending_payload }
        it 'updates message callback' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::SENDING)
        end
        it 'does not update message sent_at' do
          expect { job.perform }.to_not change{message.reload.sent_at}.from(nil)
        end
        it 'does not change conversation status' do
          expect { job.perform }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'does not create a ledger entry' do
          expect { job.perform }.to_not change{message.reload.ledger_entry}.from(nil)
        end
      end

      context 'and message is sent' do
        let(:job) { UpdateMessageStatusJob.new sent_payload }
        it 'updates message payload' do
          expect { job.perform }.to change{message.reload.provider_update}.from(nil)
        end
        it 'updates message status' do
          expect { job.perform }.to change{message.reload.status}.to(Message::SENT)
        end
        it 'updates message sent_at' do
          expect { job.perform }.to change{message.reload.sent_at}.from(nil).to(date_sent)
        end
        it 'does not change conversation status' do
          expect { job.perform }.not_to change{message.reload.conversation(true).status}.from(Conversation::CONFIRMED)
        end
        it 'creates a ledger entry' do
          job.perform
          message.reload.ledger_entry.should_not be_nil
        end
        it 'settles ledger entry' do
          expect { job.perform }.to change{message.reload.ledger_entry(true).settled_at}.from(nil).to(date_sent)
        end
        it 'updates ledger entry costs' do
          expect { job.perform }.to change{message.reload.ledger_entry(true).value} #.to(message.reload.cost)
        end
      end
    end

#     context 'with queued # challenge message' do
#       let(:message) { create(:challenge_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       let(:extended_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'queued', 'Price' => nil, 'DateSent' => nil } }
#       it 'updates message' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         enqueue_jobs UpdateMessageStatusJob.new( extended_payload )
# #         expect {
# #           Delayed::Job.enqueue UpdateMessageStatusJob.new( extended_payload )
# #         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         work_jobs 1 #, 1, 0
# #         expect {
# #           expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
# #           @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
# #         }.to change{Delayed::Job.count}.from(1).to(0)
#         
#         # Check that the message has been properly massaged
#         message.reload
#         message.provider_update.should_not be_nil()
#         message.status.should == Message::QUEUED
#         
#         # Check that the message's ledger_entry has been properly massaged
#         message.ledger_entry(true).settled_at.should be_nil
#         
#         # Check that the message's conversation is still queued
#         message.conversation(true).status.should == Conversation::QUEUED
#       end
#     end
# 
#     context 'with sending challenge message' do
#       let(:message) { create(:challenge_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       let(:extended_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sending', 'Price' => nil, 'DateSent' => nil } }
#       it 'updates message' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         expect {
#           Delayed::Job.enqueue UpdateMessageStatusJob.new( extended_payload )
#         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         expect {
#           expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#           @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#         }.to change{Delayed::Job.count}.from(1).to(0)
#         
#         # Check that the message has been properly massaged
#         message.reload
#         message.provider_update.should_not be_nil()
#         message.status.should == Message::SENDING
#         
#         # Check that the message's ledger_entry has been properly massaged
#         message.ledger_entry(true).settled_at.should be_nil
#         
#         # Check that the message's conversation is queued
#         message.conversation(true).status.should == Conversation::QUEUED
#       end
#     end
# 
#     context 'with queued reply message' do
#       let(:message) { create(:reply_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       let(:extended_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'queued', 'Price' => nil, 'DateSent' => nil } }
#       it 'updates message' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         expect {
#           Delayed::Job.enqueue UpdateMessageStatusJob.new( extended_payload )
#         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         expect { # Do not change message's conversation's status
#           expect {
#             expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#             @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#           }.to change{Delayed::Job.count}.from(1).to(0)
#           
#           # Check that the message has been properly massaged
#           message.reload
#           message.provider_update.should_not be_nil()
#           message.status.should == Message::QUEUED
#           
#           # Check that the message's ledger_entry has been properly massaged
#           message.ledger_entry(true).settled_at.should be_nil
#         }.to_not change{message.conversation(true).status}
#         
#         # Check that the message's conversation is still queued
#         #message.conversation(true).status.should == Conversation::QUEUED
#       end
#     end
# 
#     context 'with sending reply message' do
#       let(:message) { create(:reply_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       let(:extended_payload) { create_message_update_payload message, nil, false, { 'SmsStatus' => 'sending', 'Price' => nil, 'DateSent' => nil } }
#       it 'updates message' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         expect {
#           Delayed::Job.enqueue UpdateMessageStatusJob.new( extended_payload )
#         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         expect { # Do not change message's conversation's status
#           expect {
#             expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#             @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#           }.to change{Delayed::Job.count}.from(1).to(0)
#           
#           # Check that the message has been properly massaged
#           message.reload
#           message.provider_update.should_not be_nil()
#           message.status.should == Message::SENDING
#           
#           # Check that the message's ledger_entry has been properly massaged
#           message.ledger_entry(true).settled_at.should be_nil
#           
#           # Check that the message's conversation is queued
#         }.to_not change{message.conversation(true).status}
#       end
#     end
# 
#     context 'with sent challenge message' do
#       let(:message) { create(:challenge_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       it 'updates challenge message and ledger_entry' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         expect {
#           job = UpdateMessageStatusJob.new( payload )
#           Delayed::Job.enqueue job
#         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         expect {
#           expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#           @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#         }.to change{Delayed::Job.count}.from(1).to(0)
#         
#         # Check that the message has been properly massaged
#         message.reload
#         message.provider_update.should_not be_nil()
#         message.status.should == Message::SENT
#         
#         # Check that the message's ledger_entry has been properly massaged
#         message.ledger_entry(true).settled_at.should == date_sent
#         
#         # Check that the message's conversation has been refreshed
#         message.conversation(true).challenge_status.should == Message::SENT
#         message.conversation.challenge_sent_at.should == date_sent
#       end
#     end
#     context 'with sent reply message' do
#       let(:message) { create(:reply_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
#       it 'updates reply message and ledger_entry' do
#         message.provider_update.should be_nil()
#   
#         # Capture job count, enqueue job, and check that it has been added
#         expect {
#           job = UpdateMessageStatusJob.new( payload )
#           Delayed::Job.enqueue job
#         }.to change{Delayed::Job.count}.from(0).to(1)
#         
#         # Now, work that job!
#         expect {
#           expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#           @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#         }.to change{Delayed::Job.count}.from(1).to(0)
#         
#         # Check that the message has been properly massaged
#         message.reload
#         message.provider_update.should_not be_nil()
#         message.status.should == Message::SENT
#         
#         # Check that the message's ledger_entry has been properly massaged
#         message.ledger_entry(true).settled_at.should == date_sent
#         
#         # Check that the message's conversation has been refreshed
#         message.conversation(true).reply_status.should == Message::SENT
#         message.conversation.reply_sent_at.should == date_sent
#       end
#     end
  end
  
  describe '#standardise_callback_values' do
    let(:payload) { { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, Test: 'my test', 'HelloThere' => 'hi' } }
    let(:standardised_payload) { { 'sms_sid' => 'xxx', 'sms_status' => 'sent', 'price' => 0.01, 'test' => 'my test', 'hello_there' => 'hi' } }
    subject { UpdateMessageStatusJob.new( payload ) }

    its(:standardise_callback_values) { should be_an_instance_of(HashWithIndifferentAccess) }
    its(:standardise_callback_values) { should eq( standardised_payload ) }
  end
  
  describe '#standardise_callback_values!' do
    it 'should update own callback values' do
      expected_payload = { sms_sid: 'yyy', price: 0.04, sms_status: 'sending' }
      job = UpdateMessageStatusJob.new( expected_payload )
      job.callback_values.should eq( expected_payload )
      job.standardise_callback_values!
      job.callback_values.should eq( expected_payload.with_indifferent_access )
    end
  end
  
  describe '#requires_requerying_status?' do
    it 'should require requerying (1)' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx' } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should require requerying (2)' do
      job = UpdateMessageStatusJob.new( { sms_status: 'pending' } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should require requerying (3)' do
      job = UpdateMessageStatusJob.new( { price: 0.01 } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should require requerying (4)' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'pending' } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should require requerying (5)' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', price: 0.04 } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should require requerying (6)' do
      job = UpdateMessageStatusJob.new( { sms_status: 'pending', price: 0.04 } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_true
    end
    it 'should not require requerying' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, date_sent: DateTime.now } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_false
    end
    it 'should not require requerying although it has lots more data than required' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, ostriches: true, walruses: false, date_sent: DateTime.now } )
      job.requires_requerying_sms_status?( job.callback_values ).should be_false
    end
  end

end
