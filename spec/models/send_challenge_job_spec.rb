require 'spec_helper'

describe SendChallengeJob do
  fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets
  before { VCR.insert_cassette 'send_challenge_job', record: :new_episodes }
  after { VCR.eject_cassette }

  describe '.new' do
    it 'should create new without forced resend' do
      expected_ticket = tickets(:test_ticket)
      job = SendChallengeJob.new( expected_ticket.id )
      job.ticket_id.should eq( expected_ticket.id )
      job.force_resend?.should == false
    end
    it 'should create new with false forced resend' do
      expected_ticket = tickets(:test_ticket)
      job = SendChallengeJob.new( expected_ticket.id, false )
      job.ticket_id.should eq( expected_ticket.id )
      job.force_resend?.should == false
    end
    it 'should create new with true forced resend' do
      expected_ticket = tickets(:test_ticket)
      job = SendChallengeJob.new( expected_ticket.id, true )
      job.ticket_id.should eq( expected_ticket.id )
      job.force_resend?.should == true
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

    it 'should perform when ticket has not been sent yet' do
      @appliance = appliances(:test_appliance)
      @ticket = @appliance.open_ticket( to_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' )
      @ticket.save!

      # Get counts
      messages_count = @ticket.messages.count
      transactions_count = @ticket.appliance.account.transactions.count
      
      # Capture job count, enqueue job, and check that it has been added
      Delayed::Job.count.should == 0
      job_count = Delayed::Job.count
      job = SendChallengeJob.new( @ticket.id, false, true )
      Delayed::Job.enqueue job
      Delayed::Job.count.should == job_count + 1
      
      # Now, work that job!
      expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
      @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
      Delayed::Job.count.should == 1 # It should enqueue another job (an expire job)
      
      # Check that the ticket status is updated
      @ticket.reload
      @ticket.status.should == Ticket::QUEUED
      @ticket.challenge_status.should == Ticket::QUEUED

      # Check that a message and a transaction were built
      @ticket.messages.count.should == messages_count + 1
      @ticket.appliance.account.transactions.count.should == transactions_count + 1
    end

    it 'should not perform when ticket has already been sent' do
      @appliance = appliances(:test_appliance)
      @ticket = @appliance.open_ticket( to_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' )
      @ticket.challenge_sent = DateTime.now # Forces job to 'pretend' it has been sent successfully
      @ticket.challenge_status = Message::SENT
      @ticket.status = Ticket::CHALLENGE_SENT
      @ticket.save!

      # Get counts
      messages_count = @ticket.messages.count
      transactions_count = @ticket.appliance.account.transactions.count
      
      # Capture job count, enqueue job, and check that it has been added
      Delayed::Job.count.should == 0
      job_count = Delayed::Job.count
      job = SendChallengeJob.new( @ticket.id, false, true )
      Delayed::Job.enqueue job
      Delayed::Job.count.should == job_count + 1
      
      # Now, work that job!
      expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
      @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
      Delayed::Job.count.should == 0
      
      # Check that the ticket status is updated
      @ticket.reload
      @ticket.status.should == Ticket::CHALLENGE_SENT
      @ticket.challenge_status.should == Message::SENT

      # Check that a message and a transaction were NOT built
      @ticket.messages.count.should == messages_count
      @ticket.appliance.account.transactions.count.should == transactions_count
    end

    it 'should perform with error handling' do
      @appliance = appliances(:test_appliance)
      @ticket = @appliance.open_ticket( to_number: Twilio::INVALID_NUMBER, expected_confirmed_answer: 'YES' )
      @ticket.save!

      # Get counts
      messages_count = @ticket.messages.count
      transactions_count = @ticket.appliance.account.transactions.count
      
      # Capture job count, enqueue job, and check that it has been added
      Delayed::Job.count.should == 0
      job_count = Delayed::Job.count
      job = SendChallengeJob.new( @ticket.id, false, true )
      Delayed::Job.enqueue job
      Delayed::Job.count.should == job_count + 1
      
      # Now, work that job! - No error, but will close out the job
      expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
      @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
      Delayed::Job.count.should == 0
      
      # Check that the ticket status is updated
      @ticket.reload
      @ticket.status.should == Ticket::ERROR_INVALID_TO
      @ticket.challenge_status.should == Ticket::ERROR_INVALID_TO

      # Check that a message and a transaction were NOT built
      @ticket.messages.count.should == messages_count
      @ticket.appliance.account.transactions.count.should == transactions_count
    end

  end
  
end
