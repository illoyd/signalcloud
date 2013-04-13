require 'spec_helper'

describe SendTicketChallengeJob, :vcr => { :cassette_name => "send_challenge_job" } do

  describe '.new' do
    let(:ticket)  { create(:ticket) }
    context 'with ticket and default resend' do
      subject       { SendTicketChallengeJob.new( ticket.id ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and without resend' do
      subject       { SendTicketChallengeJob.new( ticket.id, false ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and with resend' do
      subject       { SendTicketChallengeJob.new( ticket.id, true ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_true }
      its(:ticket) { should_not be_nil }
    end
  end
  
  describe '#perform' do
    let(:account)           { create(:account, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, account: account) }

    context 'when ticket has not been sent' do
      let(:ticket)  { create(:ticket, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendTicketChallengeJob.new( ticket.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{ticket.messages(true).count}.by(1)
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.stencil.account.ledger_entries.count}
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
      let(:ticket)  { create(:ticket, :challenge_sent, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendTicketChallengeJob.new( ticket.id ) }
      it 'does not create a new message' do
        expect { job.perform }.to_not change{ticket.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.stencil.account.ledger_entries.count}
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
    
    context 'with invalid TO number' do
      let(:ticket)  { create(:ticket, stencil: stencil, to_number: Twilio::INVALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendTicketChallengeJob.new( ticket.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{ticket.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        job.perform
        ticket.messages(true).order('created_at').last.status.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.stencil.account.ledger_entries.count}
      end
      it 'changes ticket status to error' do
        expect { job.perform }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'changes ticket challenge status to error' do
        expect { job.perform }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_TO)
      end
      it 'does not enqueue an expiration job' do
        expect { job.perform }.to_not change{Delayed::Job.count}
      end
    end

    context 'with invalid FROM number' do
      let(:ticket)  { create(:ticket, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendTicketChallengeJob.new( ticket.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{ticket.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        job.perform
        ticket.messages(true).order('created_at').last.status.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{ticket.stencil.account.ledger_entries(true).count}
      end
      it 'changes ticket status to error' do
        expect { job.perform }.to change{ticket.reload.status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'changes ticket challenge status to error' do
        expect { job.perform }.to change{ticket.reload.challenge_status}.to(Ticket::ERROR_INVALID_FROM)
      end
      it 'does not enqueue an expiration job' do
        expect { job.perform }.to_not change{Delayed::Job.count}
      end
    end

  end
  
end
