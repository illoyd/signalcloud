# Twilio API items
TWILIO_SID_LENGTH = 34

##
# Patch for Twilio::TwiML::Response to support .to_s and .to_xml
module Twilio
  module TwiML
    class Response
      def to_s
        return self.text
      end
      def to_xml( options = nil )
        return self.text
      end
    end
  end
end
