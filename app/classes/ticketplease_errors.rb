module Ticketplease

##
# Standard Ticketplease error, which includes options for a nested +original+ error and error +code+.
class TicketpleaseError < StandardError
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
class AccountNotAssociatedError < TicketpleaseError
  def initialize( original = nil, code = nil )
    super( 'Object not associated to an account.', original, code )
  end
end

##
# Twilio Error!
class TwilioError < TicketpleaseError; end

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
# FreshBooks Error!
class FreshBooksError < TicketpleaseError; end

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

class TicketError < TicketpleaseError
  attr_accessor :ticket
  def initialize( msg, ticket, original = nil, code = nil )
    super( msg, original, code )
    self.ticket = ticket
  end
end

class MessageError < TicketpleaseError
  attr_accessor :ticket_message
  def initialize( msg, ticket_message, original = nil, code = nil )
    super( msg, original, code )
    self.ticket_message = ticket_message
  end
end

class TicketSendingError < TicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'Ticket encountered an error while sending.', ticket, original, code )
  end
end

class MessageSendingError < MessageError
  def initialize(message, original = nil, code = nil)
    super( 'Ticket encountered an error while sending (code %i).' % [code], message, original, code )
  end
end

class CriticalMessageSendingError < MessageSendingError
end

class InvalidTicketStateError < TicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket is in an invalid state.', ticket, original, code )
  end
end

class ChallengeAlreadySentError < TicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket challenge has already been sent. Use force_resend to resend the message.', ticket, original, code )
  end
end

class ReplyAlreadySentError < TicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket reply has already been sent. Use force_resend to resend the message.', ticket, original, code )
  end
end

class ClientInvoiceNotCreatedError < TicketpleaseError
  def initialize(original = nil, code = nil)
    super( 'The invoice has not been created in the financial system.', original, code )
  end
end

class ClientInvoiceAlreadyCreatedError < TicketpleaseError
  def initialize(original = nil, code = nil)
    super( 'The invoice has already been created in the financial system.', original, code )
  end
end


end
