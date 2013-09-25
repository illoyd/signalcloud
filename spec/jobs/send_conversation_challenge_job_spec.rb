require 'spec_helper'

describe SendConversationChallengeJob, :vcr do

  describe '#perform' do
    let(:organization)    { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, organization: organization) }

    context 'when conversation has not been sent' do
      let(:conversation)  { create(:conversation, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: Twilio::VALID_NUMBER) }
      it 'creates a new message' do
        expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
      end
      it 'does not create a new ledger entry' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries.count}
      end
      it 'sets conversation workflow_state to queued' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to(Conversation::QUEUED)
      end
      it 'sets conversations challenge status to queued' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.challenge_status}.to(Message::QUEUED)
      end
      it 'enqueues another expiration job' do
        expect { subject.perform( conversation.id ) }.to change{ExpireConversationJob.jobs.count}.by(1)
      end
    end

    context 'when conversation has been sent' do
      let(:conversation)  { create(:conversation, :challenge_sent, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: Twilio::VALID_NUMBER) }
      it 'does not create a new message' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.messages(true).count}
      end
      it 'does not create a new ledger entry' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries.count}
      end
      it 'does not change conversation workflow_state' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.workflow_state}
      end
      it 'does not change conversation challenge status' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.challenge_status}
      end
      it 'does not enqueue another expiration job' do
        expect { subject.perform( conversation.id ) }.to_not change{ExpireConversationJob.jobs.count}
      end
    end
    
    context 'with invalid TO number' do
      let(:conversation)  { create(:conversation, stencil: stencil, customer_number: Twilio::INVALID_NUMBER, internal_number: Twilio::VALID_NUMBER) }
      it 'creates a new message' do
        expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        subject.perform( conversation.id )
        conversation.messages(true).order('created_at').last.workflow_state.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries.count}
      end
      it 'changes conversation workflow_state to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to(Conversation::ERROR_INVALID_TO)
      end
      it 'changes conversation challenge status to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.challenge_status}.to(Conversation::ERROR_INVALID_TO)
      end
      it 'does not enqueue an expiration job' do
        expect { subject.perform( conversation.id ) }.to_not change{ExpireConversationJob.jobs.count}
      end
    end

    context 'with invalid FROM number' do
      let(:conversation)  { create(:conversation, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: Twilio::INVALID_NUMBER) }
      it 'creates a new message' do
        expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        subject.perform( conversation.id )
        conversation.messages(true).order('created_at').last.workflow_state.should == Message::FAILED
      end
      it 'does not create a new ledger entry' do
        expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries(true).count}
      end
      it 'changes conversation workflow_state to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to(Conversation::ERROR_INVALID_FROM)
      end
      it 'changes conversation challenge status to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.challenge_status}.to(Conversation::ERROR_INVALID_FROM)
      end
      it 'does not enqueue an expiration job' do
        expect { subject.perform( conversation.id ) }.to_not change{ExpireConversationJob.jobs.count}
      end
    end

  end
  
end
