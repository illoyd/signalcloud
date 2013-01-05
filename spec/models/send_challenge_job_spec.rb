require 'spec_helper'

describe SendChallengeJob do
  fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets
  
  # it { should allow_mass_assignment_of(:ticket_id) }
  
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
      expect{ @work_results = Delayed::Worker.new.work_off }.to_not raise_error
      @work_results.sum.should == 1 # Should have only processed one job before exiting
      @work_results.second.should == 0 # Check for failures first
      @work_results.first.should == 1 # Then check for success
      Delayed::Job.count.should == 0

      # Check that a message and a transaction were built
      @ticket.messages.count.should == messages_count + 1
      @ticket.appliance.account.transactions.count.should == transactions_count + 1
    end
  end
  
end
