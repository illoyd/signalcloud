require 'spec_helper'

describe SendTicketReplyJob do
  before(:all) { VCR.insert_cassette 'send_ticket_reply_job' }
  after(:all)  { VCR.eject_cassette }

  describe '.new' do
    let(:ticket)  { create(:ticket) }
    context 'with ticket and default resend' do
      subject       { SendTicketReplyJob.new( ticket.id ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and without resend' do
      subject       { SendTicketReplyJob.new( ticket.id, false ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_false }
      its(:ticket) { should_not be_nil }
    end
    context 'with ticket and with resend' do
      subject       { SendTicketReplyJob.new( ticket.id, true ) }
      its(:ticket_id) { should eq (ticket.id) }
      its(:force_resend) { should be_true }
      its(:ticket) { should_not be_nil }
    end
  end
  
  describe '#perform' do
    let(:account)           { create(:account, :test_twilio, :with_sid_and_token) }
    let(:appliance)         { create(:appliance, account: account) }

    [ :confirmed, :denied, :failed, :expired ].each do |status|

      context "when ticket #{status.to_s} reply has not been sent" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, status, appliance: appliance) }
        let(:job)     { SendTicketReplyJob.new( ticket.id ) }
        it 'does not raise error' do
          expect { job.perform }.to_not raise_error
        end
        it 'creates a new message' do
          expect { job.perform }.to change{ticket.messages(true).count}.by(1)
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
        it 'sets tickets reply status to queued' do
          expect { job.perform }.to change{ticket.reload.reply_status}.to(Message::QUEUED)
        end
      end

      context "when ticket #{status.to_s} reply has been sent" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, :reply_sent, appliance: appliance) }
        let(:job)     { SendTicketReplyJob.new( ticket.id ) }
        it 'does not raise error' do
          expect { job.perform }.to_not raise_error
        end
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
        it 'does not change ticket reply status' do
          expect { job.perform }.to_not change{ticket.reload.reply_status}
        end
      end

    end

  end
  
end
