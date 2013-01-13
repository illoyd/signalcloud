require 'spec_helper'

describe UpdateMessageStatusJob do
  fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets, :messages

  describe '.new' do
    it 'should create new' do
      expected_ticket = tickets(:test_ticket)
      job = SendChallengeJob.new( expected_ticket.id )
      job.ticket_id.should eq( expected_ticket.id )
    end
  end
  
  describe '.find_ticket' do
    it 'should find ticket' do
      expected_ticket = tickets(:test_ticket)
      job = SendChallengeJob.new( expected_ticket.id )
      job.find_ticket.should eq( expected_ticket )
    end
  end
  
  describe '.perform' do
    it 'should update challenge message and transaction' do
      @message = messages(:test_ticket_challenge)
      @message.callback_payload.should_not be_nil()
      
      # Construct a callback payload
      date_sent = 15.seconds.ago
      payload = { sid: @message.twilio_sid, date_sent: date_sent, status: 'sent', price: 0.044 }

      # Capture job count, enqueue job, and check that it has been added
      Delayed::Job.count.should == 0
      job = UpdateMessageStatusJob.new( payload )
      Delayed::Job.enqueue job
      Delayed::Job.count.should == 1
      
      # Now, work that job!
      expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
      @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
      Delayed::Job.count.should == 0 # Queue should be empty
      
      # Check that the ticket status is updated
      @message.reload
      @message.settled_at.should_not be_nil()
      @message.ticket.status.should == Ticket::CHALLENGE_SENT
      @message.ticket.challenge_status.should == Ticket::SENT
      @message.ticket.challenge_sent.should == date_sent
    end
  end
  
end
