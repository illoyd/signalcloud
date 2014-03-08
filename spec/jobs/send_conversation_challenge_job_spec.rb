require 'spec_helper'

describe SendConversationChallengeJob, :vcr do

  SendConversationChallengeJob_OPEN_STATES = [ :draft ]
  SendConversationChallengeJob_CLOSED_STATES = [ :asking, :asked, :receiving, :received, :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired, :errored ]
  
  # Verifies that all states are tested
  it 'tests all possible workflow states' do
    ( Conversation.workflow_spec.state_names - SendConversationChallengeJob_OPEN_STATES - SendConversationChallengeJob_CLOSED_STATES ).should be_empty
  end

  describe '#perform' do
    let(:organization)    { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, organization: organization) }

    SendConversationChallengeJob_OPEN_STATES.each do |state|
      context "when conversation is #{state} and not sent" do
        let(:conversation)  { create(:conversation, state, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: Twilio::VALID_NUMBER) }
        it 'creates a new message' do
          expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
        end
        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'transitions state to asking' do
          expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to('asking')
        end
        it 'sets conversation challenge state to sending' do
          expect { subject.perform( conversation.id ) }.to change{conversation.reload.challenge_status}.to('sending')
        end
        it 'does not change conversation reply state' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.reply_status}
        end
        it 'enqueues an expiration job' do
          expect { subject.perform( conversation.id ) }.to change{ExpireConversationJob.jobs.count}.by(1)
        end
      end
    end # open states

    SendConversationChallengeJob_CLOSED_STATES.each do |state|
      context "when conversation is #{state} and sent" do
        let(:conversation)  { create(:conversation, state, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: Twilio::VALID_NUMBER) }
        it 'does not create a new message' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.messages(true).count}
        end
        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'does not change conversation state' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.workflow_state}
        end
        it 'does not change conversation challenge state' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.challenge_status}
        end
        it 'does not change conversation reply state' do
          expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.reply_status}
        end
        it 'does not enqueue an expiration job' do
          expect { subject.perform( conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
        end
      end
    end
    
    shared_examples 'a failed message' do
      let(:phone_book)       { create :phone_book, organization: organization }
      let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
      let(:stencil)          { create :stencil, organization: organization, phone_book: phone_book }
      before(:each)          { phone_book_entry }

      it 'creates a new message' do
        expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
      end
      it 'fails newly created message' do
        subject.perform( conversation.id )
        conversation.messages(true).order('created_at').last.errored?.should be_true
      end
      it 'does not create a new ledger entry' do
        expect { subject.perform( conversation.id ) }.not_to change{conversation.stencil.organization.ledger_entries(true).count}
      end
      it 'changes conversation workflow_state to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.workflow_state}.to('errored')
      end
      it 'changes conversation challenge status to error' do
        expect { subject.perform( conversation.id ) }.to change{conversation.reload.challenge_status}.to('errored')
      end
      it 'does not change conversation reply status' do
        expect { subject.perform( conversation.id ) }.not_to change{conversation.reload.reply_status}
      end
      it 'does not enqueue an expiration job' do
        expect { subject.perform( conversation.id ) }.not_to change{ExpireConversationJob.jobs.count}
      end

    end

    context 'with invalid TO number' do
      let(:phone_number)     { create :phone_number, number: Twilio::VALID_NUMBER, organization: organization, communication_gateway: organization.communication_gateway_for(:twilio) }
      let(:conversation)     { create :conversation, :draft, :real, stencil: stencil, customer_number: Twilio::INVALID_NUMBER, internal_number: phone_number.number }
      it_behaves_like 'a failed message'
    end

    context 'with invalid FROM number' do
      let(:phone_number)     { create :phone_number, number: Twilio::INVALID_NUMBER, organization: organization, communication_gateway: organization.communication_gateway_for(:twilio) }
      let(:conversation)     { create :conversation, :draft, :real, stencil: stencil, customer_number: Twilio::VALID_NUMBER, internal_number: phone_number.number }
      it_behaves_like 'a failed message'
    end

  end
  
end
