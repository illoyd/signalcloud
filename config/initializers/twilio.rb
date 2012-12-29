# Twilio API items
TWILIO_SID_LENGTH = 34

##
# Patch for Twilio::TwiML::Response to support .to_s and .to_xml
module Twilio

  ##
  # REST API interface
  module REST

    ##
    # Message object
    class Message
      ##
      # Convert the 'payload' of the message back into a hash class, for ease of use later
      def to_property_hash
        properties = {}
        [ :sid, :date_created, :date_updated, :date_sent, :account_sid, :to, :from, :body, :status, :direction, :api_version, :price ].map do |property|
          properties[property] = self.send(property) if self.respond_to?(property)
        end
        return properties
      end
    end
  end

  ##
  # TwiML 
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
