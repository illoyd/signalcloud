require 'spec_helper'

describe SendChallengeJob do
  fixtures :accounts, :phone_directories, :appliances, :tickets
  
  # it { should allow_mass_assignment_of(:ticket_id) }
  
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
  
end
