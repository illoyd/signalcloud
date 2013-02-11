require 'spec_helper'

describe InboundMessageJob do
  before { VCR.insert_cassette 'inbound_message_job', record: :new_episodes }
  after { VCR.eject_cassette }
  
  def construct_inbound_payload( options={} )
    options.reverse_merge({
      'SmsSid' => 'SM5e27df39904bc98686355dd7ec98f8a9',
      'AccountSid' => ENV['TWILIO_TEST_ACCOUNT_SID'],
      'From' => Twilio::VALID_NUMBER,
      'To' => Twilio::VALID_NUMBER,
      'Body' => 'Hello!'
    })
  end
  
  describe '#perform' do
    let(:account)       { create(:account, :test_twilio) }
    let(:appliance)     { create(:appliance, account: account) }
    let(:phone_number)  { create(:valid_phone_number, account: account) }
    let(:customer_number)  { build(:valid_phone_number) }
    subject { InboundMessageJob.new(payload) }

    context 'when unsolicited (no matching ticket)' do
      let(:payload) { construct_inbound_payload( 'To' => phone_number.number, 'From' => customer_number.number ) }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'queues unsolicited message job' do
        expect { subject.perform }.to change{Delayed::Job.count}.by(1)
      end
    end
    
    context 'when replying to open ticket' do
      let(:ticket)  { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number.number) }
      let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
    end
    
    context 'when replying to expired ticket' do
      let(:ticket)  { create(:ticket, :challenge_sent, :expired, appliance: appliance, expiry: 180.seconds.ago, from_number: phone_number.number, to_number: customer_number.number) }
      let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
    end
    
    [ :confirmed, :denied, :failed ].each do |status|
      context "when replying to #{status.to_s} but not sent ticket" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, status, appliance: appliance, from_number: phone_number.number, to_number: customer_number.number) }
        let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
      end
      context "when replying to #{status.to_s} and sent ticket" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, status, :reply_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number.number) }
        let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
      end
    end
    
  end #perform
  
end
