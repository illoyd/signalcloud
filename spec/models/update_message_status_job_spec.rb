require 'spec_helper'

describe UpdateMessageStatusJob do
  fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets, :messages

  describe '.new' do
    it 'should create new' do
      expected_payload = { sms_sid: 'yyy', price: 0.04, sms_status: 'sending' }
      job = UpdateMessageStatusJob.new( expected_payload )
      job.callback_values.should eq( expected_payload )
    end
  end
  
  describe '.perform' do
    it 'should update challenge message and transaction' do
      #pending 'Testing child processes first'
      @message = messages(:test_ticket_challenge)
      @message.callback_payload.should be_nil()
      
      # Construct a callback payload
      date_sent = 15.seconds.ago
      payload = { sms_sid: @message.twilio_sid, date_sent: date_sent, sms_status: 'sent', price: 0.04 }

      # Capture job count, enqueue job, and check that it has been added
      Delayed::Job.count.should == 0
      job = UpdateMessageStatusJob.new( payload )
      Delayed::Job.enqueue job
      Delayed::Job.count.should == 1
      
      # Now, work that job!
      expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
      @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
      Delayed::Job.count.should == 0 # Queue should be empty
      
      # Check that the message has been properly massaged
      @message.reload
      @message.callback_payload.should_not be_nil()
      @message.status.should == Message::SENT
      
      # Check that the message's transaction has been properly massaged
      @message.transaction(true).settled_at.should == date_sent
      
      # Check that the message's ticket has been refreshed
      @message.ticket(true).status.should == Ticket::CHALLENGE_SENT
      @message.ticket.challenge_status.should == Message::SENT
      @message.ticket.challenge_sent.should == date_sent
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
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should require requerying (2)' do
      job = UpdateMessageStatusJob.new( { sms_status: 'pending' } )
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should require requerying (3)' do
      job = UpdateMessageStatusJob.new( { price: 0.01 } )
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should require requerying (4)' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'pending' } )
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should require requerying (5)' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', price: 0.04 } )
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should require requerying (6)' do
      job = UpdateMessageStatusJob.new( { sms_status: 'pending', price: 0.04 } )
      job.requires_requerying_status?( job.callback_values ).should == true
    end
    it 'should not require requerying' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, date_sent: DateTime.now } )
      job.requires_requerying_status?( job.callback_values ).should == false
    end
    it 'should not require requerying although it has lots more data than required' do
      job = UpdateMessageStatusJob.new( { sms_sid: 'xxx', sms_status: 'sent', price: 0.01, ostriches: true, walruses: false, date_sent: DateTime.now } )
      job.requires_requerying_status?( job.callback_values ).should == false
    end
  end

end
