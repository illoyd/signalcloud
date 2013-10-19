module Twilio
  class DirectionTransformer
    INBOUND  = %w( in inbound )
    OUTBOUND = %w( outbound outbound-api outbound-call outbound-reply out )
    def self.transform(v)
      ActiveSupport::StringInquirer.new case v.to_s.downcase
        when *OUTBOUND; ::Message::OUT
        when *INBOUND;  ::Message::IN
        else raise SignalCloud::TransformError.new( "Unrecognised direction: #{v}" )
      end
    end
  end
end