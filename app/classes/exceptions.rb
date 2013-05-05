module SignalCloud

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

##
# Thrown whenever the given object does not have an associated account. This is a CRITICAL error as no
# object should ever be created without an account!
class AccountNotAssociatedError < SignalCloudError
  def initialize( original = nil, code = nil )
    super( 'Object not associated to an account.', original, code )
  end
end

##
# Twilio Error!
class TwilioError < SignalCloudError; end

##
# Thrown whenever a Twilio client is requested but not configured.
class MissingTwilioAccountError < TwilioError
  def initialize( account, original = nil, code = nil )
    super( 'Twilio not configured for Account %i.' % [account.id], original, code )
  end
end

##
# Thrown if attempting to create a Twilio account for an Account which already has a Twilio account.
class TwilioAccountAlreadyExistsError < TwilioError
  def initialize( account, original = nil, code = nil )
    super( 'Twilio already exists for Account %i.' % [account.id], original, code )
  end
end

##
# Thrown if attempting to create a Twilio application for an Account which already has a Twilio account.
class TwilioApplicationAlreadyExistsError < TwilioError
  def initialize( account, original = nil, code = nil )
    super( 'Twilio application already exists for Account %i.' % [account.id], original, code )
  end
end

##
# Thrown if attempting to use a Twilio application for an Account which does not have an application configured.
class MissingTwilioApplicationError < TwilioError
  def initialize( account, original = nil, code = nil )
    super( 'Twilio application not configured for Account %i.' % [account.id], original, code )
  end
end

##
# FreshBooks Error!
class FreshBooksError < SignalCloudError; end

##
# Thrown whenever the given item does not have a FreshBooks account yet.
class MissingFreshBooksClientError < FreshBooksError
  def initialize( account, original = nil, code = nil )
    super( 'FreshBooks client not created for Account %i.' % [account.id], original, code )
  end
end

##
# Thrown if attempting to create a FreshBooks client for an Account which already has a FreshBooks client.
class FreshBooksClientAlreadyExistsError < FreshBooksError
  def initialize( account, original = nil, code = nil )
    super( 'FreshBooks client already exists for Account %i.' % [account.id], original, code )
  end
end

class ConversationError < SignalCloudError
  attr_accessor :conversation
  def initialize( msg, conversation, original = nil, code = nil )
    super( msg, original, code )
    self.conversation = conversation
  end
end

class MessageError < SignalCloudError
  attr_accessor :conversation_message
  def initialize( msg, conversation_message, original = nil, code = nil )
    super( msg, original, code )
    self.conversation_message = conversation_message
  end
end

class ConversationSendingError < ConversationError
  def initialize(conversation, original = nil, code = nil)
    super( 'Conversation encountered an error while sending.', conversation, original, code )
  end
end

class MessageSendingError < MessageError
  def initialize(message, original = nil, code = nil)
    super( 'Conversation encountered an error while sending (code %i).' % [code], message, original, code )
  end
end

class CriticalMessageSendingError < MessageSendingError
end

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
