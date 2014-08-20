require 'spec_helper'

describe Twilio::StatusTransformer do

  describe '.call' do
    
    it { expect( described_class.call('sent') ).to     eq(::Message::SENT_SZ) }

    it { expect( described_class.call('sending') ).to  eq(::Message::SENDING_SZ) }

    it { expect( described_class.call('queued') ).to   eq(::Message::PENDING_SZ) }
    it { expect( described_class.call('pending') ).to  eq(::Message::PENDING_SZ) }

    it { expect( described_class.call('received') ).to eq(::Message::RECEIVED_SZ) }

    it { expect( described_class.call('failed') ).to   eq(::Message::FAILED_SZ) }
    
    it { expect{ described_class.call('se') }.to       raise_error(SignalCloud::TransformError) }
    it { expect{ described_class.call('f') }.to        raise_error(SignalCloud::TransformError) }
    it { expect{ described_class.call('ostrich') }.to  raise_error(SignalCloud::TransformError) }

  end

end