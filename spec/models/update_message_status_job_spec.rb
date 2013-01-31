require 'spec_helper'

describe UpdateMessageStatusJob do
  fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets, :messages
  before { VCR.insert_cassette 'update_message_status_job', record: :new_episodes }
  after { VCR.eject_cassette }
  
  def create_message_update_payload( message, body=nil, reply=false, others={} )
    body = message.ticket.question if body.nil?
    {
      'AccountSid' => message.ticket.account.twilio_account_sid,
      'SmsSid' =>     message.twilio_sid,
      'ApiVersion' => '2010-04-01',
      'From' =>       reply ? message.ticket.to_number : message.ticket.from_number,
      'To' =>	        reply ? message.ticket.from_number : message.ticket.to_number,
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
  
  describe '.perform' do
    let(:date_sent) { 15.seconds.ago }
    let(:payload) { create_message_update_payload message, nil, false, { 'Price' => -0.04, 'DateSent' => date_sent } }
    context 'with challenge message' do
      let(:message) { create(:challenge_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
      it 'updates challenge message and ledger_entry' do
        message.callback_payload.should be_nil()
  
        # Capture job count, enqueue job, and check that it has been added
        expect {
          job = UpdateMessageStatusJob.new( payload )
          Delayed::Job.enqueue job
        }.to change{Delayed::Job.count}.from(0).to(1)
        
        # Now, work that job!
        expect {
          expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
          @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
        }.to change{Delayed::Job.count}.from(1).to(0)
        
        # Check that the message has been properly massaged
        message.reload
        message.callback_payload.should_not be_nil()
        message.status.should == Message::SENT
        
        # Check that the message's ledger_entry has been properly massaged
        message.ledger_entry(true).settled_at.should == date_sent
        
        # Check that the message's ticket has been refreshed
        message.ticket(true).challenge_status.should == Message::SENT
        message.ticket.challenge_sent.should == date_sent
      end
    end
    context 'with reply message' do
      let(:message) { create(:reply_message, twilio_sid: 'SM1f3eb5e1e6e7e00ad9d0b415a08efb58') }
      it 'updates reply message and ledger_entry' do
        message.callback_payload.should be_nil()
  
        # Capture job count, enqueue job, and check that it has been added
        expect {
          job = UpdateMessageStatusJob.new( payload )
          Delayed::Job.enqueue job
        }.to change{Delayed::Job.count}.from(0).to(1)
        
        # Now, work that job!
        expect {
          expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
          @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
        }.to change{Delayed::Job.count}.from(1).to(0)
        
        # Check that the message has been properly massaged
        message.reload
        message.callback_payload.should_not be_nil()
        message.status.should == Message::SENT
        
        # Check that the message's ledger_entry has been properly massaged
        message.ledger_entry(true).settled_at.should == date_sent
        
        # Check that the message's ticket has been refreshed
        message.ticket(true).reply_status.should == Message::SENT
        message.ticket.reply_sent.should == date_sent
      end
    end
  end
  
  describe '.standardise_callback_values' do
    let(:payload) { { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, Test: 'my test', 'HelloThere' => 'hi' } }
    let(:standardised_payload) { { 'sms_sid' => 'xxx', 'sms_status' => 'sent', 'price' => 0.01, 'test' => 'my test', 'hello_there' => 'hi' } }
    subject { UpdateMessageStatusJob.new( payload ) }
    its(:standardise_callback_values) { should be_an_instance_of(HashWithIndifferentAccess) }
    its(:standardise_callback_values) { should eq( standardised_payload ) }
  end
  
  describe '.standardise_callback_values!' do
    it 'should update own callback values' do
      expected_payload = { sms_sid: 'yyy', price: 0.04, sms_status: 'sending' }
      job = UpdateMessageStatusJob.new( expected_payload )
      job.callback_values.should eq( expected_payload )
      job.standardise_callback_values!
      job.callback_values.should eq( expected_payload.with_indifferent_access )
    end
  end
  
  describe '.requires_requerying_status?' do
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
