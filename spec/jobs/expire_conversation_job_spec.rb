require 'spec_helper'

describe ExpireConversationJob, :vcr do
  # subject { ExpireConversationJob.new }
  
  ExpireConversationJob_OPEN_STATES = [ :asking, :asked ]
  ExpireConversationJob_CLOSED_STATES = [ :draft, :receiving, :received, :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired, :errored ]
  
  # Verifies that all states are tested
  it 'tests all possible workflow states' do
    expect( Conversation.workflow_spec.state_names - ExpireConversationJob_OPEN_STATES - ExpireConversationJob_CLOSED_STATES ).to be_empty
  end

  describe '#perform' do
    let(:organization)            { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)                 { create(:stencil, organization: organization) }

    ExpireConversationJob_OPEN_STATES.each do |state|
      context "when conversation is #{state}" do
  
        context 'and conversation has not yet passed expiration' do
          let(:conversation)      { create :conversation, state, stencil: stencil, expires_at: 900.seconds.from_now }
          
          it 'assigns the correct state' do
            expect(conversation.workflow_state).to eq(state.to_s)
          end

          it 'finds the open conversation' do
            expect(subject.send(:find_conversation, conversation.id)).to be_a Conversation
          end
  
          it 'does not raise error' do
            expect { subject.perform( conversation.id ) }.not_to raise_error
          end
  
          it 'does not change conversation status' do
            expect { subject.perform( conversation.id ) }.not_to change{conversation.workflow_state}
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
          let(:conversation)      { create :conversation, state, stencil: stencil, expires_at: 900.seconds.ago }

          it 'assigns the correct state' do
            expect(conversation.workflow_state).to eq(state.to_s)
          end

          it 'finds the open conversation' do
            expect(subject.send(:find_conversation, conversation.id)).to be_a Conversation
          end
  
          it 'does not raise error' do
            expect { subject.perform( conversation.id ) }.not_to raise_error
          end
  
          it 'changes conversation status' do
            expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to('expiring')
          end
  
          it 'does not enqueue a follow-up expire job' do
            expect { subject.perform( conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
          end
  
          it 'creates a new ledger entry' do
            skip
            expect { subject.perform( conversation.id ) }.to change{conversation.stencil.organization.ledger_entries(true).count}
          end
  
          it 'creates a new message' do
            expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
          end
        end
      end
    end
    
    ExpireConversationJob_CLOSED_STATES.each do |state|

      context "when conversation is #{state}" do
        let(:conversation) { create :conversation, state, stencil: stencil, expires_at: 900.seconds.ago }
        
        it 'assigns the correct state' do
          expect(conversation.workflow_state).to eq(state.to_s)
        end

        it 'cannot find an open conversation' do
          expect(subject.send(:find_conversation, conversation.id)).to be_nil
        end
  
        it 'does not raise error' do
          expect { subject.perform( conversation.id ) }.not_to raise_error
        end
  
        it 'does not change conversation status' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.workflow_state}
        end
  
        it 'does not enqueue a follow-up expire job' do
          expect { subject.perform( conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
        end
  
        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.stencil.organization.ledger_entries(true).count}
        end
  
        it 'does not create a new message' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.messages(true).count}
        end
      end

    end

  end #perform
  
end
