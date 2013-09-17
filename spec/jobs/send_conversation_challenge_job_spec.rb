require 'spec_helper'

describe SendConversationChallengeJob, :vcr do

  describe '.new' do
    let(:conversation)  { create(:conversation) }
    context 'with conversation and default resend' do
      subject       { SendConversationChallengeJob.new( conversation.id ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_false }
      its(:conversation) { should_not be_nil }
    end
    context 'with conversation and without resend' do
      subject       { SendConversationChallengeJob.new( conversation.id, false ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_false }
      its(:conversation) { should_not be_nil }
    end
    context 'with conversation and with resend' do
      subject       { SendConversationChallengeJob.new( conversation.id, true ) }
      its(:conversation_id) { should eq (conversation.id) }
      its(:force_resend) { should be_true }
      its(:conversation) { should_not be_nil }
    end
  end
  
  describe '#perform' do
    let(:organization)           { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, organization: organization) }

    context 'when conversation has not been sent' do
      let(:conversation)  { create(:conversation, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendConversationChallengeJob.new( conversation.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{conversation.messages(true).count}.by(1)
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{conversation.stencil.organization.ledger_entries.count}
      end
      it 'sets conversation status to queued' do
        expect { job.perform }.to change{conversation.reload.status}.to(Conversation::QUEUED)
      end
      it 'sets conversations challenge status to queued' do
        expect { job.perform }.to change{conversation.reload.challenge_status}.to(Message::QUEUED)
      end
      it 'enqueues another expiration job' do
        expect { job.perform }.to change{Sidekiq::Stats.new.enqueued}.by(1)
      end
    end

    context 'when conversation has been sent' do
      let(:conversation)  { create(:conversation, :challenge_sent, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendConversationChallengeJob.new( conversation.id ) }
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
      it 'does not enqueue another expiration job' do
        expect { job.perform }.to_not change{Sidekiq::Stats.new.enqueued}
      end
    end
    
    context 'with invalid TO number' do
      let(:conversation)  { create(:conversation, stencil: stencil, to_number: Twilio::INVALID_NUMBER, from_number: Twilio::VALID_NUMBER) }
      let(:job)     { SendConversationChallengeJob.new( conversation.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{conversation.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        job.perform
        conversation.messages(true).order('created_at').last.status.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{conversation.stencil.organization.ledger_entries.count}
      end
      it 'changes conversation status to error' do
        expect { job.perform }.to change{conversation.reload.status}.to(Conversation::ERROR_INVALID_TO)
      end
      it 'changes conversation challenge status to error' do
        expect { job.perform }.to change{conversation.reload.challenge_status}.to(Conversation::ERROR_INVALID_TO)
      end
      it 'does not enqueue an expiration job' do
        expect { job.perform }.to_not change{Sidekiq::Stats.new.enqueued}
      end
    end

    context 'with invalid FROM number' do
      let(:conversation)  { create(:conversation, stencil: stencil, to_number: Twilio::VALID_NUMBER, from_number: Twilio::INVALID_NUMBER) }
      let(:job)     { SendConversationChallengeJob.new( conversation.id ) }
      it 'creates a new message' do
        expect { job.perform }.to change{conversation.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        job.perform
        conversation.messages(true).order('created_at').last.status.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { job.perform }.to_not change{conversation.stencil.organization.ledger_entries(true).count}
      end
      it 'changes conversation status to error' do
        expect { job.perform }.to change{conversation.reload.status}.to(Conversation::ERROR_INVALID_FROM)
      end
      it 'changes conversation challenge status to error' do
        expect { job.perform }.to change{conversation.reload.challenge_status}.to(Conversation::ERROR_INVALID_FROM)
      end
      it 'does not enqueue an expiration job' do
        expect { job.perform }.to_not change{Sidekiq::Stats.new.enqueued}
      end
    end

  end
  
end
