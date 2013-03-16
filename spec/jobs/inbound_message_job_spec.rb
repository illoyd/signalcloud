require 'spec_helper'

describe InboundMessageJob do
  before(:all) { VCR.insert_cassette 'inbound_message_job' }
  after(:all)  { VCR.eject_cassette }
  
  let(:account)          { create(:account, :master_twilio) }
  let(:phone_directory)  { create(:phone_directory, account: account) }
  let(:appliance)        { create(:appliance, account: account, phone_directory: phone_directory) }
  let(:phone_number)     { create(:us_phone_number, account: account) }
  let(:customer_number)  { Twilio::VALID_NUMBER }

#   before(:each) { Message.destroy_all(twilio_sid: 'SM5e27df39904bc98686355dd7ec98f8a9') }
  
  def construct_inbound_payload( options={} )
    options.reverse_merge({
      'SmsSid' => 'SM5e27df39904bc98686355dd7ec98f8a9',
      'AccountSid' => ENV['TWILIO_TEST_ACCOUNT_SID'],
      'From' => Twilio::VALID_NUMBER,
      'To' => Twilio::VALID_NUMBER,
      'Body' => 'Hello!'
    })
  end
  
  describe '#normalize_provider_update' do
    let(:payload) { construct_inbound_payload( 'To' => Twilio::VALID_NUMBER, 'From' => Twilio::INVALID_NUMBER ) }
    subject { InboundMessageJob.new(payload) }
    its(:normalize_provider_update) { should be_a(HashWithIndifferentAccess) }
    [ :to, :sms_sid, :account_sid, :from, :body ].each do |key|
      its(:normalize_provider_update) { should have_key key }
    end
  end
  
  describe '#normalize_provider_update!' do
    let(:payload) { construct_inbound_payload( 'To' => Twilio::VALID_NUMBER, 'From' => Twilio::INVALID_NUMBER ) }
    let(:normalized_payload) { subject.normalize_provider_update }
    subject { InboundMessageJob.new(payload) }
    it 'replaces existing provider_update' do
      expect{ subject.normalize_provider_update! }.to change{subject.provider_update}.to(normalized_payload)
    end
    it 'makes provider_update indifferent' do
      subject.normalize_provider_update!
      subject.provider_update.should be_a HashWithIndifferentAccess
    end
  end
  
  describe '#internal_phone_number' do
    let(:ticket)        { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
    let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
    subject { InboundMessageJob.new(payload) }
    
    its(:internal_phone_number) { should be_a PhoneNumber }
    its('internal_phone_number.id') { should == phone_number.id }
    its('internal_phone_number.number') { should == phone_number.number }
  end
  
  describe '#perform' do

    context 'when unsolicited (no matching ticket)' do
      let(:payload) { construct_inbound_payload( 'To' => phone_number.number, 'From' => customer_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_tickets) { should be_empty }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
#       it 'queues unsolicited message job' do
#         expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#       end
    end
    
    context 'when replying to open ticket' do
      let(:ticket)  { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
      let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_tickets) { should have(1).item }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'queues response message and webhook jobs' do
        expect { subject.perform }.to change{Delayed::Job.count}.by(2)
      end
    end
    
    context 'when replying to multiple open ticket' do
      let!(:ticket)   { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
      let!(:ticketA)  { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
      let!(:ticketB)  { create(:ticket, :challenge_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
      let(:payload)   { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_tickets) { should have(3).items }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'closes one ticket' do
        expect { subject.perform }.to change{subject.find_open_tickets.count}.by(-1)
      end
      it 'queues response message and webhook jobs' do
        expect { subject.perform }.to change{Delayed::Job.count}.by(2)
      end
    end
    
    context 'when replying to expired ticket' do
      let(:ticket)  { create(:ticket, :challenge_sent, :expired, appliance: appliance, expiry: 180.seconds.ago, from_number: phone_number.number, to_number: customer_number) }
      let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
      subject { InboundMessageJob.new(payload) }

      its(:find_open_tickets) { should be_empty }
      its(:internal_phone_number) { should_not be_nil }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
#       it 'queues unsolicited message job' do
#         expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#       end
    end
    
    [ :confirmed, :denied, :failed ].each do |status|
      context "when replying to #{status.to_s} but not sent ticket" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, status, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
        subject { InboundMessageJob.new(payload) }

        its(:find_open_tickets) { should be_empty }
        its(:internal_phone_number) { should_not be_nil }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
#         it 'queues unsolicited message job' do
#           expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#         end
      end
      context "when replying to #{status.to_s} and sent ticket" do
        let(:ticket)  { create(:ticket, :challenge_sent, :response_received, status, :reply_sent, appliance: appliance, from_number: phone_number.number, to_number: customer_number) }
        let(:payload) { construct_inbound_payload( 'To' => ticket.from_number, 'From' => ticket.to_number ) }
        subject { InboundMessageJob.new(payload) }

        its(:find_open_tickets) { should be_empty }
        its(:internal_phone_number) { should_not be_nil }
        it 'does not raise error' do
          expect { subject.perform }.to_not raise_error
        end
#         it 'queues unsolicited message job' do
#           expect { subject.perform }.to change{Delayed::Job.count}.by(1)
#         end
      end
    end
    
  end #perform
  
end
