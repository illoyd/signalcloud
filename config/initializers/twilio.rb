# Twilio API items
TWILIO_SID_LENGTH = 34

##
# Patch for Twilio::TwiML::Response to support .to_s and .to_xml
module Twilio

  # 'Magic Numbers' for test cases
  VALID_NUMBER = '+15005550006'  
  INVALID_NUMBER = '+15005550001'

  # Number buying-specific 'Magic Numbers'
  UNAVAILABLE_NUMBER = '+15005550000'
  AVAILABLE_AREACODE = '500'
  UNAVAILABLE_AREACODE = '533'

  # SMS-specific 'Magic Numbers'
  INVALID_NOT_SMS_CAPABLE_FROM_NUMBER = '+15005550007'
  INVALID_FULL_SMS_QUEUE_NUMBER = '+15005550008'  
  INVALID_CANNOT_ROUTE_TO_NUMBER = '+15005550002'
  INVALID_INTERNATIONAL_NUMBER = '+15005550003'
  INVALID_BLACKLISTED_NUMBER = '+15005550004'
  INVALID_NOT_SMS_CAPABLE_TO_NUMBER = '+15005550009'

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
