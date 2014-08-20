require 'spec_helper'

describe Twilio::DirectionTransformer do

  describe '.call' do
    
    it { expect( described_class.call('in') ).to             eq(::Message::IN) }
    it { expect( described_class.call('inbound') ).to        eq(::Message::IN) }

    it { expect( described_class.call('out') ).to            eq(::Message::OUT) }
    it { expect( described_class.call('outbound') ).to       eq(::Message::OUT) }
    it { expect( described_class.call('outbound-api') ).to   eq(::Message::OUT) }
    it { expect( described_class.call('outbound-call') ).to  eq(::Message::OUT) }
    it { expect( described_class.call('outbound-reply') ).to eq(::Message::OUT) }
    
    it { expect{ described_class.call('i') }.to raise_error(SignalCloud::TransformError) }
    it { expect{ described_class.call('o') }.to raise_error(SignalCloud::TransformError) }
    it { expect{ described_class.call('ostrich') }.to raise_error(SignalCloud::TransformError) }

  end

end