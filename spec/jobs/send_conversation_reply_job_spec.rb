require 'spec_helper'

describe SendConversationReplyJob, :vcr do

  describe '#perform' do
    let(:organization)    { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)         { create(:stencil, organization: organization) }

    [ :confirmed, :denied, :failed, :expired ].each do |status|

      context "when conversation #{status.to_s} reply has not been sent" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, status, stencil: stencil) }
        it 'does not raise error' do
          expect { subject.perform( conversation.id ) }.to_not raise_error
        end
        it 'creates a new message' do
          expect { subject.perform( conversation.id ) }.to change{conversation.messages(true).count}.by(1)
        end
        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'does not change conversation status' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.status}
        end
        it 'does not change conversation challenge status' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.challenge_status}
        end
        it 'sets conversations reply status to queued' do
          expect { subject.perform( conversation.id ) }.to change{conversation.reload.reply_status}.to(Message::QUEUED)
        end
      end

      context "when conversation #{status.to_s} reply has been sent" do
        let(:conversation)  { create(:conversation, :challenge_sent, :response_received, :reply_sent, stencil: stencil) }
        it 'does not raise error' do
          expect { subject.perform( conversation.id ) }.to_not raise_error
        end
        it 'does not create a new message' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.messages(true).count}
        end
        it 'does not create a new ledger entry' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.stencil.organization.ledger_entries.count}
        end
        it 'does not change conversation status' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.status}
        end
        it 'does not change conversation challenge status' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.challenge_status}
        end
        it 'does not change conversation reply status' do
          expect { subject.perform( conversation.id ) }.to_not change{conversation.reload.reply_status}
        end
      end

    end

  end
  
end
