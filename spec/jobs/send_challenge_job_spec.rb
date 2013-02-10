require 'spec_helper'

describe SendChallengeJob do
  before { VCR.insert_cassette 'send_challenge_job', record: :new_episodes }
  after  { VCR.eject_cassette }

  describe '.new' do
    let(:ticket)  { create(:ticket) }
    context 'with ticket and default resend' do
      subject       { SendChallengeJob.new( ticket.id ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and without resend' do
      subject       { SendChallengeJob.new( ticket.id, false ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and with resend' do
      subject       { SendChallengeJob.new( ticket.id, true ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_true }
      its(:ticket) { should_not be_nil }
    end
  end
  
  describe '#perform' do
    let(:account)           { create(:account, :test_twilio) }
    let(:appliance)         { create(:appliance, account: account) }

    context 'when ticket has not been sent' do
      let(:ticket)  { create(:ticket, appliance: appliance) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{ticket.messages(true).count}.by(1)
      end
      it 'creates a new ledger entry' do
        expect { job.perform }.to change{ticket.appliance.account.ledger_entries.count}.by(1)
      end
      it 'sets ticket status to queued' do
        expect { job.perform }.to change{ticket.reload.status}.to(Ticket::QUEUED)
      end
      it 'sets tickets challenge status to queued' do
        expect { job.perform }.to change{ticket.reload.challenge_status}.to(Message::QUEUED)
      end
      it 'enqueues another expiration job' do
        expect { job.perform }.to change{Delayed::Job.count}.by(1)
      end
    end

    context 'when ticket has been sent' do
      let(:ticket)  { create(:ticket, :challenge_sent, appliance: appliance) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { job.perform }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.appliance.account.ledger_entries.count}
      end
      it 'does not change ticket status' do
        expect { job.perform }.to_not change{ticket.reload.status}
      end
      it 'does not change ticket challenge status' do
        expect { job.perform }.to_not change{ticket.reload.challenge_status}
      end
      it 'does not enqueue another expiration job' do
        expect { job.perform }.to_not change{Delayed::Job.count}
      end
    end
    
    context 'with invalid to number' do
      let(:ticket)  { create(:ticket, appliance: appliance, to_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { job.perform }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.appliance.account.ledger_entries.count}
      end
      it 'changes ticket status to error' do
        expect { job.perform }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'changes ticket challenge status to error' do
        expect { job.perform }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'does not enqueue another expiration job' do
        expect { job.perform }.to_not change{Delayed::Job.count}
      end
    end

    context 'with invalid from number' do
      let(:ticket)  { create(:ticket, appliance: appliance, to_number: Twilio::VALID_NUMBER, from_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { job.perform }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.appliance.account.ledger_entries(true).count}
      end
      it 'changes ticket status to error' do
        expect { job.perform }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'changes ticket challenge status to error' do
        expect { job.perform }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'does not enqueue another expiration job' do
        expect { job.perform }.to_not change{Delayed::Job.count}
      end
    end

  end
  
end
