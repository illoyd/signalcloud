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
  # Twilio's standardised SID length. This is effectively an identifier (2) and random (32) string.
  SID_LENGTH = 34
  
  ##
  # SMS direction label for inbound messages.
  SMS_INBOUND_API = 'inbound-api'
  
  ##
  # SMS direction label for outbound messages.
  SMS_OUTBOUND_API = 'outbound-api'

  ##
  # SMS Status flags
  SMS_STATUS_SENT = 'sent'
  SMS_STATUS_SENDING = 'sending'
  SMS_STATUS_QUEUED = 'queued'
  SMS_STATUS_RECEIVED = 'received'
  SMS_STATUS_FAILED = 'failed'

  ##
  # Purchasing error codes
  ERR_PHONE_NUMBER_NOT_AVAILABLE = 21452

  ##
  # SMS Error codes
  ERR_INVALID_TO_PHONE_NUMBER = 21211
  ERR_INVALID_FROM_PHONE_NUMBER = 21212
  ERR_FROM_PHONE_NUMBER_NOT_SMS_CAPABLE = 21606
  ERR_TO_PHONE_NUMBER_IS_BLACKLISTED = 21610
  ERR_FROM_PHONE_NUMBER_EXCEEDED_QUEUE_SIZE = 21611
  ERR_TO_PHONE_NUMBER_CANNOT_RECEIVE_SMS = 21612
  ERR_TO_PHONE_NUMBER_NOT_VALID_MOBILE = 21614
  ERR_SMS_BODY_REQUIRED = 21602
  ERR_SMS_BODY_EXCEEDS_MAXIMUM_LENGTH = 21605
  ERR_SMS_TO_REQUIRED = 21604
  ERR_SMS_FROM_REQUIRED = 21603
  
  ##
  # Critical error codes - these should never occur in a production environment
  ERR_INTERNATIONAL_NOT_ENABLED = 21408
  
  def self.master_client
    Twilio::REST::Client.new ENV['TWILIO_MASTER_ACCOUNT_SID'], ENV['TWILIO_MASTER_AUTH_TOKEN']
  end
  
  def self.test_client
    Twilio::REST::Client.new ENV['TWILIO_TEST_ACCOUNT_SID'], ENV['TWILIO_TEST_AUTH_TOKEN']
  end
  
  def self.assumed_phone_number_price( country_code )
    case country_code.upcase
      when 'US', 'CA', 'GB'
        1.00
      else
        0.00
    end
  end

  ##
  # REST API interface
  module REST

    class InstanceResource
    
      ##
      # Test if the object is loaded from Twilio. We test this by querying for the existance of additional methods on the object.
      def is_loaded?
        !(self.methods - self.class.instance_methods).empty?
      end

      ##
      # Convert the 'payload' of the message into a hash class, for ease of use later
      def to_property_hash
        self.refresh unless self.is_loaded?
        (self.methods - self.class.instance_methods).each_with_object(HashWithIndifferentAccess.new) do |property, properties|
          properties[property] = self.send(property) if self.respond_to?(property)
        end
      end

      ##
      # Convert the 'payload' of the message into a ApiSmith::Smash class, if available. Otherwise, default back to a hash.
      def to_property_smash
        properties = self.to_property_hash
        properties = self.class::Smash.new( properties ) if self.class.has_smash?
        return properties
      end
      
      ##
      # Check if a Smash is available for this class
      def self.has_smash?
        self.const_defined?('Smash')
      end
    end

    ##
    # SMS send responses are returned to the application from the Twilio ruby API. These are odd criters that need extra management.
    class Message
      class Smash < ::APISmith::Smash
  
        # Required fields
        property :sid,        required: true
        property :account_sid

        property :created_at, from: :date_created, transformer: lambda { |v| Time.parse(v) rescue nil }
        property :updated_at, from: :date_updated, transformer: lambda { |v| Time.parse(v) rescue nil }
        property :sent_at,    from: :date_sent,    transformer: lambda { |v| Time.parse(v) rescue nil }

        property :to,         required: true
        alias_method :customer_number, :to

        property :from,       required: true
        alias_method :internal_number, :from

        property :body,       required: true
        
        property :status,     required: true, transformer: lambda { |v| ActiveSupport::StringInquirer.new Twilio::StatusTransformer.transform(v) }
        property :direction,  required: true, transformer: lambda { |v| ActiveSupport::StringInquirer.new Twilio::DirectionTransformer.transform(v) }

        property :price,      transformer: lambda { |v| BigDecimal.new v rescue nil }
        property :price_unit

        property :segments,   from: :num_segments

        property :api_version

        delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
        delegate :inbound?, :outbound?, to: :direction
        
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
