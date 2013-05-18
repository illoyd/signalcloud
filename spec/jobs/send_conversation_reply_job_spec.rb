require 'spec_helper'

describe SendConversationReplyJob, :vcr do

  describe '.new' do
    let(:conversation)  { create(:conversation) }
    context 'with conversation and default resend' do
      subject       { SendConversationReplyJob.new( conversation.id ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_false }
      its(:conversation) { should_not be_nil }
    end
    context 'with conversation and without resend' do
      subject       { SendConversationReplyJob.new( conversation.id, false ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_false }
      its(:conversation) { should_not be_nil }
    end
    context 'with conversation and with resend' do
      subject       { SendConversationReplyJob.new( conversation.id, true ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_true }
      its(:conversation) { should_not be_nil }
    end
  end
  
  describe '#perform' do
    let(:organization)         { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, organization: organization) }

    [ :confirmed, :denied, :failed, :expired ].each do |status|

      context "when conversation #{status.to_s} reply has not been sent" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, status, stencil: stencil) }
        let(:job)     { SendConversationReplyJob.new( conversation.id ) }
        it 'does not raise error' do
          expect { job.perform }.to_not raise_error
        end
        it 'creates a new message' do
          expect { job.perform }.to change{conversation.messages(true).count}.by(1)
        end
        it 'does not create a new ledger entry' do
          expect { job.perform }.to_not change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'does not change conversation status' do
          expect { job.perform }.to_not change{conversation.reload.status}
        end
        it 'does not change conversation challenge status' do
          expect { job.perform }.to_not change{conversation.reload.challenge_status}
        end
        it 'sets conversations reply status to queued' do
          expect { job.perform }.to change{conversation.reload.reply_status}.to(Message::QUEUED)
        end
      end

      context "when conversation #{status.to_s} reply has been sent" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, :reply_sent, stencil: stencil) }
        let(:job)     { SendConversationReplyJob.new( conversation.id ) }
        it 'does not raise error' do
          expect { job.perform }.to_not raise_error
        end
        it 'does not create a new message' do
          expect { job.perform }.to_not change{conversation.messages(true).count}
        end
        it 'does not create a new ledger entry' do
          expect { job.perform }.to_not change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'does not change conversation status' do
          expect { job.perform }.to_not change{conversation.reload.status}
        end
        it 'does not change conversation challenge status' do
          expect { job.perform }.to_not change{conversation.reload.challenge_status}
        end
        it 'does not change conversation reply status' do
          expect { job.perform }.to_not change{conversation.reload.reply_status}
        end
      end

    end

  end
  
end
