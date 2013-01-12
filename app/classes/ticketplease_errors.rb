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
    super( 'Account not associated to object.', original, code )
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
  attr_accessor :message
  def initialize( msg, message, original = nil, code = nil )
    super( msg, original, code )
    self.message = message
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

class CriticalMessageSendingError < MessageError
  def initialize(message, original = nil, code = nil)
    super( 'Ticket encountered a critical error while sending (code %i).' % [code], message, original, code )
  end
end

class InvalidTicketStateError < TicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket is in an invalid state.', ticket, original, code )
    self.ticket = ticket
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

end
