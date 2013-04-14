require 'spec_helper'

describe SendTicketStatusWebhookJob, :vcr => { :cassette_name => "send_ticket_status_webhook_job" } do

  describe '#perform' do

    context 'when ticket has a webhook uri' do
      let(:account)   { create(:account, :test_twilio, :with_sid_and_token, id: 1) }
      let(:stencil)   { create(:stencil, account: account, id: 1) }
      let(:ticket)    { create(:ticket, id: 1, stencil: stencil, webhook_uri: 'http://requestb.in/p5ox1hp5', created_at: DateTime.parse('2013-01-01'), updated_at: DateTime.parse('2013-01-02')) }
      subject { SendTicketStatusWebhookJob.new ticket.id, TicketSerializer.new(ticket).as_json }

      it 'does not throw error' do
        expect { subject.perform }.not_to raise_error
      end

    end

    context 'when ticket does not have a webhook uri' do
      let(:ticket) { create :ticket, webhook_uri: nil }
      subject { SendTicketStatusWebhookJob.new ticket.id, TicketSerializer.new(ticket).as_json }

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
