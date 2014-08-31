module SignalCloud

class Error < StandardError
  attr_accessor :original
  def initialize( msg = nil, original = $! )
    super( msg || original.try(:message) )
    @original = original
  end
  def code
    self.class.const_defined?(:CODE) ? self.class.get_const(:CODE) : nil
  end
end

class TransformError < Error; end

class UnknownPriceSheetError < Error
  def initialize( country, original = $! )
    super( "No price sheet for country '#{country}.'", original )
  end
end

class UnpriceableObjectError < Error
  def initialize( object, original = $! )
    super( "Can not price '#{ object }' (#{ object.class }).", original )
  end
end

class ProviderCodeError < Error
  def provider_code
    self.original.try(:code)
  end
end

##
# An exception class for communicating all communication gateway errors.
class CommunicationGatewayError < ProviderCodeError
  attr_accessor :communication_gateway
  def initialize( communication_gateway, code = nil, msg = nil, original = $! )
    super( msg, original )
    @communication_gateway = communication_gateway
  end
end

class MessageDeliveryCommunicationGatewayError < CommunicationGatewayError; CODE=400.1; end
class InvalidToNumberCommunicationGatewayError < MessageDeliveryCommunicationGatewayError; CODE=400.2; end
class InvalidFromNumberCommunicationGatewayError < MessageDeliveryCommunicationGatewayError; CODE=400.3; end
class InvalidMessageBodyCommunicationGatewayError < MessageDeliveryCommunicationGatewayError; CODE=400.4; end

class CriticalCommunicationGatewayError < CommunicationGatewayError; CODE=500; end
class CommunicationGatewayConfigurationError < CriticalCommunicationGatewayError; end


##
# An exception class for communicating all message errors.
class MessageError < Error
  attr_accessor :conversation_message
  def initialize( conversation_message, msg = nil, original = $! )
    super( msg, original )
    @conversation_message = conversation_message
  end
end

##
# An exception class for communicating all critical message errors.
class CriticalMessageError < MessageError; end

##
# Raised when the message's 'To' number is invalid.
class InvalidToNumberMessageSendingError < CriticalMessageError; CODE=400.1; end

##
# Raised when the message's 'From' number is invalid.
class InvalidFromNumberMessageSendingError < CriticalMessageError; CODE=400.2; end

##
# Raised when the message's 'From' number is invalid.
class InvalidBodyMessageSendingError < CriticalMessageError; CODE=400.3; end






##
# Standard SignalCloud error, which includes options for a nested +original+ error and error +code+.
class SignalCloudError < StandardError
  attr_accessor :original
  attr_accessor :code
  
  def initialize( msg = nil, original = nil, code = nil )
    super( msg )
    self.original = original
    self.code = code
  end

end

class WebhookMissingError < SignalCloudError; end

class ObjectNotSavedError < SignalCloudError
  def initialize( original = nil, code = nil )
    super( 'Object not saved.', original, code )
  end
end

##
# Thrown whenever the given object does not have an associated organization. This is a CRITICAL error as no
# object should ever be created without an organization!
class OrganizationNotAssociatedError < SignalCloudError
  def initialize( original = nil, code = nil )
    super( 'Object not associated to an organization.', original, code )
  end
end

##
# Thrown if attempting to create or update the FreshBooks client when missing necessary contact data.
class MissingContactDetailsError < SignalCloudError
  def initialize( organization, original = nil, code = nil )
    super( 'Missing organization (%s) contact details.' % [organization.id || '[New]'], original, code )
  end
end

##
# Twilio Error!
class TwilioError < SignalCloudError; end

##
# Thrown whenever a Twilio client is requested but not configured.
class MissingTwilioAccountError < TwilioError
  def initialize( organization, original = nil, code = nil )
    super( 'Twilio not configured for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

##
# Thrown if attempting to create a Twilio organization for an Organization which already has a Twilio organization.
class TwilioAccountAlreadyExistsError < TwilioError
  def initialize( organization, original = nil, code = nil )
    super( 'Twilio already exists for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

##
# Thrown if attempting to create a Twilio application for an Organization which already has a Twilio organization.
class TwilioApplicationAlreadyExistsError < TwilioError
  def initialize( organization, original = nil, code = nil )
    super( 'Twilio application already exists for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

##
# Thrown if attempting to use a Twilio application for an Organization which does not have an application configured.
class MissingTwilioApplicationError < TwilioError
  def initialize( organization, original = nil, code = nil )
    super( 'Twilio application not configured for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

class MissingTwilioInstanceError < TwilioError
  def initialize( instance, original = nil, code = nil )
    super( 'Twilio not configured for %s %s.' % [instance.class.name, instance.id || '[New]'], original, code )
  end
end

##
# FreshBooks Error!
class FreshBooksError < SignalCloudError; end

class FreshBooksApiError < FreshBooksError
  def initialize( response, original = nil, code = nil )
    super( 'FreshBooks API: %s (%s).' % [response['error'], response['code']], original, code )
  end
end

##
# Thrown whenever the given item does not have a FreshBooks organization yet.
class MissingFreshBooksClientError < FreshBooksError
  def initialize( organization, original = nil, code = nil )
    super( 'FreshBooks client not created for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

##
# Thrown if attempting to create a FreshBooks client for an Organization which already has a FreshBooks client.
class FreshBooksClientAlreadyExistsError < FreshBooksError
  def initialize( organization, original = nil, code = nil )
    super( 'FreshBooks client already exists for Organization %s.' % [organization.id || '[New]'], original, code )
  end
end

class ConversationError < SignalCloudError
  attr_accessor :conversation
  def initialize( msg, conversation, original = nil, code = nil )
    super( msg, original, code )
    self.conversation = conversation
  end
end

# class MessageError < SignalCloudError
#   attr_accessor :conversation_message
#   def initialize( msg, conversation_message, original = nil, code = nil )
#     super( msg, original, code )
#     self.conversation_message = conversation_message
#   end
# end

class ConversationSendingError < ConversationError
  def initialize(conversation, original = nil, code = nil)
    super( 'Conversation encountered an error while sending.', conversation, original, code )
  end
end

# class MessageSendingError < MessageError
#   def initialize(message, original = nil, code = nil)
#     super( 'Conversation encountered an error while sending (code %i). Original is "%s".' % [code, original], message, original, code )
#   end
# end

# class CriticalMessageSendingError < MessageSendingError
# end



# class MessageSending2Error < SignalCloudError; end
# class CriticalMessageSending2Error < MessageSending2Error; end
# 
# class InvalidToError < CriticalMessageSending2Error
#   def initialize( original=nil )
#     super( 'The \'To\' number is missing or malformed.', original, 1001 )
#   end
# end
# 
# class InvalidFromError < CriticalMessageSending2Error
#   def initialize( original=nil )
#     super( 'The \'From\' number is missing or malformed.', original, 1002 )
#   end
# end



class InvalidConversationStateError < ConversationError
  def initialize(conversation, original = nil, code = nil)
    super( 'The conversation is in an invalid state.', conversation, original, code )
  end
end

class ChallengeAlreadySentError < ConversationError
  def initialize(conversation, original = nil, code = nil)
    super( 'The conversation challenge has already been sent. Use force_resend to resend the message.', conversation, original, code )
  end
end

class ReplyAlreadySentError < ConversationError
  def initialize(conversation, original = nil, code = nil)
    super( 'The conversation reply has already been sent. Use force_resend to resend the message.', conversation, original, code )
  end
end

class ClientInvoiceNotCreatedError < SignalCloudError
  def initialize(original = nil, code = nil)
    super( 'The invoice has not been created in the financial system.', original, code )
  end
end

class ClientInvoiceAlreadyCreatedError < SignalCloudError
  def initialize(original = nil, code = nil)
    super( 'The invoice has already been created in the financial system.', original, code )
  end
end

end
