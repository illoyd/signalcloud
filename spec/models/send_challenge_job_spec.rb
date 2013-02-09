require 'spec_helper'

describe SendChallengeJob do
  #fixtures :account_plans, :accounts, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets
  before { VCR.insert_cassette 'send_challenge_job', record: :new_episodes }
  after { VCR.eject_cassette }

  describe '.new' do
    context 'with ticket and default resend' do
      let(:ticket)  { create(:ticket) }
      subject       { SendChallengeJob.new( ticket.id ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:'force_resend?') { should be_false }
    end
    context 'with ticket and without resend' do
      let(:ticket)  { create(:ticket) }
      subject       { SendChallengeJob.new( ticket.id, false ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:'force_resend?') { should be_false }
    end
    context 'with ticket and with resend' do
      let(:ticket)  { create(:ticket) }
      subject       { SendChallengeJob.new( ticket.id, true ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:'force_resend?') { should be_true }
    end
#     let(:ticket)            { create(:ticket, appliance: appliance) }
#     it 'creates new without forced resend' do
#       expected_ticket = tickets(:test_ticket)
#       job = SendChallengeJob.new( expected_ticket.id )
#       job.ticket_id.should eq( expected_ticket.id )
#       job.force_resend?.should be_false
#     end
#     it 'creates new with false forced resend' do
#       expected_ticket = tickets(:test_ticket)
#       job = SendChallengeJob.new( expected_ticket.id, false )
#       job.ticket_id.should eq( expected_ticket.id )
#       job.force_resend?.should be_false
#     end
#     it 'creates new with true forced resend' do
#       expected_ticket = tickets(:test_ticket)
#       job = SendChallengeJob.new( expected_ticket.id, true )
#       job.ticket_id.should eq( expected_ticket.id )
#       job.force_resend?.should be_true
#     end
  end
  
  describe '#find_ticket' do
    #it 'finds ticket' do
      let(:ticket)  { create(:ticket) }
      subject       { SendChallengeJob.new( ticket.id, true ) }
      #expected_ticket = tickets(:test_ticket)
      #job = SendChallengeJob.new( expected_ticket.id )
      its(:find_ticket) { should eq(ticket) }
    #end
  end
  
  describe '#perform' do
    let(:account)           { create(:account, :test_twilio) }
    let(:appliance)         { create(:appliance, account: account) }
    #let(:ticket)            { create(:ticket, appliance: appliance) }
    let(:sent_ticket)       { create(:ticket, :challenge_sent, appliance: appliance) }
    let(:confirmed_ticket)  { create(:ticket, :challenge_sent, :response_received, :reply_sent, :confirmed, appliance: appliance) }
    let(:denied_ticket)     { create(:ticket, :challenge_sent, :response_received, :reply_sent, :denied, appliance: appliance) }
    let(:failed_ticket)     { create(:ticket, :challenge_sent, :response_received, :reply_sent, :failed, appliance: appliance) }
    let(:expired_ticket)    { create(:ticket, :challenge_sent, :response_received, :reply_sent, :expired, appliance: appliance) }

    context 'when ticket has not been sent' do
      let(:ticket)  { create(:ticket, appliance: appliance) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'creates a new message' do
        expect { # Messages count
          job.perform
        }.to change{ticket.messages(true).count}.by(1)
      end
      it 'creates a new ledger entry' do
        expect { # Ledger entry count
          job.perform
        }.to change{ticket.appliance.account.ledger_entries.count}.by(1)
      end
      it 'sets ticket status to queued' do
        expect {
          job.perform
        }.to change{ticket.reload.status}.to(Ticket::QUEUED)
      end
      it 'sets ticket\'s challenge status to queued' do
        expect {
          job.perform
        }.to change{ticket.reload.challenge_status}.to(Message::QUEUED)
      end
      it 'enqueues another expiration job' do
        expect { # Job count
          job.perform
        }.to change{Delayed::Job.count}.by(1)
      end
    end

    context 'when ticket has been sent' do
      let(:ticket)  { create(:ticket, :challenge_sent, appliance: appliance) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { # Messages count
          job.perform
        }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { # Ledger entry count
          job.perform
        }.to_not change{ticket.appliance.account.ledger_entries.count}
      end
      it 'does not change ticket status' do
        expect { # Ticket status
          job.perform
        }.to_not change{ticket.reload.status}
      end
      it 'does not change ticket challenge status' do
        expect { # Ticket challenge status
          job.perform
        }.to_not change{ticket.reload.challenge_status}
      end
      it 'does not enqueue another expiration job' do
        expect { # Job count
          job.perform
        }.to_not change{Delayed::Job.count}
      end
    end
    
    context 'with invalid to number' do
      let(:ticket)  { create(:ticket, appliance: appliance, to_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { # Messages count
          job.perform
        }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { # Ledger entry count
          job.perform
        }.to_not change{ticket.appliance.account.ledger_entries.count}
      end
      it 'changes ticket status to error' do
        expect { # Ticket status
          job.perform
        }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'changes ticket challenge status to error' do
        expect { # Ticket challenge status
          job.perform
        }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'does not enqueue another expiration job' do
        expect { # Job count
          job.perform
        }.to_not change{Delayed::Job.count}
      end
    end

    context 'with invalid from number' do
      let(:ticket)  { create(:ticket, appliance: appliance, to_number: Twilio::VALID_NUMBER, from_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { # Messages count
          job.perform
        }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { # Ledger entry count
          job.perform
        }.to_not change{ticket.appliance.account.ledger_entries.count}
      end
      it 'changes ticket status to error' do
        expect { # Ticket status
          job.perform
        }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'changes ticket challenge status to error' do
        expect { # Ticket challenge status
          job.perform
        }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'does not enqueue another expiration job' do
        expect { # Job count
          job.perform
        }.to_not change{Delayed::Job.count}
      end
    end

#     it 'should perform with error handling' do
#       @appliance = appliances(:test_appliance)
#       @ticket = @appliance.open_ticket( to_number: Twilio::INVALID_NUMBER, from_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' )
#       @ticket.save!
# 
#       # Get counts
#       messages_count = @ticket.messages.count
#       ledger_entries_count = @ticket.appliance.account.ledger_entries.count
#       
#       # Capture job count, enqueue job, and check that it has been added
#       Delayed::Job.count.should == 0
#       job_count = Delayed::Job.count
#       job = SendChallengeJob.new( @ticket.id, false )
#       Delayed::Job.enqueue job
#       Delayed::Job.count.should == job_count + 1
#       
#       # Now, work that job! - No error, but will close out the job
#       expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#       @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#       Delayed::Job.count.should == 0
#       
#       # Check that the ticket status is updated
#       @ticket.reload
#       @ticket.challenge_status.should == Ticket::ERROR_INVALID_TO
#       @ticket.status.should == Ticket::ERROR_INVALID_TO
# 
#       # Check that a message and a ledger_entry were NOT built
#       @ticket.messages.count.should == messages_count
#       @ticket.appliance.account.ledger_entries.count.should == ledger_entries_count
#     end

  end
  
end
