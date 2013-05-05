require 'spec_helper'

describe SendConversationStatusWebhookJob, :vcr do

  describe '#perform' do

    context 'when conversation has a webhook uri' do
      let(:account)   { create(:account, :test_twilio, :with_sid_and_token, id: 1) }
      let(:stencil)   { create(:stencil, account: account, id: 1) }
      let(:conversation)    { create(:conversation, id: 1, stencil: stencil, webhook_uri: 'http://requestb.in/p5ox1hp5', created_at: DateTime.parse('2013-01-01'), updated_at: DateTime.parse('2013-01-02'), expires_at: DateTime.parse('2013-01-03')) }
      subject { SendConversationStatusWebhookJob.new conversation.id, ConversationSerializer.new(conversation).as_json }

      it 'does not throw error' do
        expect { subject.perform }.not_to raise_error
      end

    end

    context 'when conversation does not have a webhook uri' do
      let(:conversation) { create :conversation, webhook_uri: nil }
      subject { SendConversationStatusWebhookJob.new conversation.id, ConversationSerializer.new(conversation).as_json }

      it 'throws error' do
        expect { subject.perform }.to raise_error
      end

    end

    context 'when missing webhook data' do
      let(:conversation) { create :conversation, webhook_uri: nil }
      subject { SendConversationStatusWebhookJob.new conversation.id, nil }

      it 'throws error' do
        expect { subject.perform }.to raise_error
      end

    end

  end #perform
  
end
