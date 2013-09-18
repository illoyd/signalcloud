require 'spec_helper'

describe ExpireConversationJob, :vcr do
  subject { ExpireConversationJob.new }

  describe '#perform' do
    #let(:stencil) { stencils(:test_stencil) }
    #let(:conversation) { stencil.open_conversation( to_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' ) }
    let(:organization)            { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)                 { create(:stencil, organization: organization) }
    let(:conversation)            { create(:conversation, stencil: stencil, expires_at: 900.seconds.from_now) }
    let(:ready_to_expire_conversation) { create(:conversation, :challenge_sent, expires_at: 900.seconds.ago, stencil: stencil) }
    let(:sent_conversation)       { create(:conversation, :challenge_sent, stencil: stencil) }
    let(:confirmed_conversation)  { create(:conversation, :challenge_sent, :response_received, :reply_sent, :confirmed, stencil: stencil) }
    let(:denied_conversation)     { create(:conversation, :challenge_sent, :response_received, :reply_sent, :denied, stencil: stencil) }
    let(:failed_conversation)     { create(:conversation, :challenge_sent, :response_received, :reply_sent, :failed, stencil: stencil) }
    let(:expired_conversation)    { create(:conversation, :challenge_sent, :response_received, :reply_sent, :expired, stencil: stencil) }

    context 'when conversation is open' do

      context 'and conversation has not yet passed expiration' do
        it 'does not raise error' do
          expect { subject.perform( conversation.id ) }.not_to raise_error
        end

        it 'does not change conversation status' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.status}
        end

        it 'enqueues a follow-up expire job' do
          expect { subject.perform( conversation.id ) }.to change{ExpireConversationJob.jobs.count}.by(1)
        end

        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.stencil.organization.ledger_entries.count}
        end

        it 'does not create a new message' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.messages.count}
        end
      end

      context 'and conversation has passed expiration' do
        it 'does not raise error' do
          expect { subject.perform( ready_to_expire_conversation.id ) }.not_to raise_error
        end

        it 'changes conversation status' do
          expect { subject.perform( ready_to_expire_conversation.id ) }.to change{ready_to_expire_conversation.reload.status}.to(Conversation::EXPIRED)
        end

        it 'does not enqueue a follow-up expire job' do
          expect { subject.perform( ready_to_expire_conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
        end

        it 'creates a new ledger entry' do
          pending { expect { subject.perform( ready_to_expire_conversation.id ) }.to change{ready_to_expire_conversation.stencil.organization.ledger_entries.count} }
        end

        it 'creates a new message' do
          expect { subject.perform( ready_to_expire_conversation.id ) }.to change{ready_to_expire_conversation.messages(true).count}.by(1)
        end
      end

    end
    
    context 'when conversation is confirmed' do
      it 'does not raise error' do
        expect { subject.perform( confirmed_conversation.id ) }.not_to raise_error
      end

      it 'does not change conversation status' do
        expect { subject.perform( confirmed_conversation.id ) }.not_to change{confirmed_conversation.reload.status}
      end

      it 'does not enqueue a follow-up expire job' do
        expect { subject.perform( confirmed_conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
      end

      it 'does not create a new ledger entry' do
        expect { subject.perform( confirmed_conversation.id ) }.not_to change{confirmed_conversation.stencil.organization.ledger_entries(true).count}
      end

      it 'does not create a new message' do
        expect { subject.perform( confirmed_conversation.id ) }.not_to change{confirmed_conversation.messages(true).count}
      end
    end
    
    context 'when conversation is denied' do
      it 'does not raise error' do
        expect { subject.perform( denied_conversation.id ) }.not_to raise_error
      end

      it 'does not change conversation status' do
        expect { subject.perform( denied_conversation.id ) }.not_to change{denied_conversation.status}
      end

      it 'does not enqueue a follow-up expire job' do
        expect { subject.perform( denied_conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
      end

      it 'does not create a new ledger entry' do
        expect { subject.perform( denied_conversation.id ) }.not_to change{denied_conversation.stencil.organization.ledger_entries.count}
      end

      it 'does not create a new message' do
        expect { subject.perform( denied_conversation.id ) }.not_to change{denied_conversation.messages.count}
      end
    end
    
    context 'when conversation has failed' do
      it 'does not raise error' do
        expect { subject.perform( failed_conversation.id ) }.not_to raise_error
      end

      it 'does not change conversation status' do
        expect { subject.perform( failed_conversation.id ) }.not_to change{failed_conversation.status}
      end

      it 'does not enqueue a follow-up expire job' do
        expect { subject.perform( failed_conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
      end

      it 'does not create a new ledger entry' do
        expect { subject.perform( failed_conversation.id ) }.not_to change{failed_conversation.stencil.organization.ledger_entries.count}
      end

      it 'does not create a new message' do
        expect { subject.perform( failed_conversation.id ) }.not_to change{failed_conversation.messages.count}
      end
    end
    
    context 'when conversation has expired' do
      it 'does not raise error' do
        expect { subject.perform( expired_conversation.id ) }.not_to raise_error
      end

      it 'does not change conversation status' do
        expect { subject.perform( expired_conversation.id ) }.not_to change{expired_conversation.status}
      end

      it 'does not enqueue a follow-up expire job' do
        expect { subject.perform( expired_conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
      end

      it 'does not create a new ledger entry' do
        expect { subject.perform( expired_conversation.id ) }.not_to change{expired_conversation.stencil.organization.ledger_entries.count}
      end

      it 'does not create a new message' do
        expect { subject.perform( expired_conversation.id ) }.not_to change{expired_conversation.messages.count}
      end
    end

  end #perform
  
end
