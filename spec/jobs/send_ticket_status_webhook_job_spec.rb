require 'spec_helper'

describe SendTicketStatusWebhookJob do
  before(:all) { VCR.insert_cassette 'send_ticket_status_webhook_job' }
  after(:all)  { VCR.eject_cassette }

  describe '#perform' do

    context 'when ticket has a webhook uri' do
      let(:ticket) { create :ticket, webhook_uri: 'http://requestb.in/tqo6n2tq' }
      subject { SendTicketStatusWebhookJob.new ticket.id, ticket.to_webhook_data }

      it 'does not throw error' do
        expect { subject.perform }.not_to raise_error
      end

    end

    context 'when ticket does not have a webhook uri' do
      let(:ticket) { create :ticket, webhook_uri: nil }
      subject { SendTicketStatusWebhookJob.new ticket.id, ticket.to_webhook_data }

      it 'throws error' do
        expect { subject.perform }.to raise_error
      end

    end

    context 'when missing webhook data' do
      let(:ticket) { create :ticket, webhook_uri: nil }
      subject { SendTicketStatusWebhookJob.new ticket.id, nil }

      it 'throws error' do
        expect { subject.perform }.to raise_error
      end

    end

  end #perform
  
end
