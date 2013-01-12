module Ticketplease

class TicketpleaseError < StandardError
  attr_accessor :original
  attr_accessor :code
  
  def initialize( msg = nil, original = nil, code = nil )
    super( msg )
    self.original = original
    self.code = code
  end

end

class AccountNotAssociatedError < TicketpleaseError
  def initialize( original = nil, code = nil )
    super( 'Account not associated to object.', original, code )
  end
end

class GenericTicketError < TicketpleaseError
  attr_accessor :ticket
  def initialize( msg, ticket, original = nil, code = nil )
    super( msg, original, code )
    self.ticket = ticket
  end
end

class TicketSendingError < GenericTicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'Ticket encountered an error while sending.', ticket, original, code )
  end
end

class InvalidTicketStateError < GenericTicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket is in an invalid state.', ticket, original, code )
    self.ticket = ticket
  end
end

class MessageAlreadySentError < GenericTicketError
  def initialize(ticket, original = nil, code = nil)
    super( 'The ticket message has already been sent. Use force_resend to resend the message.', ticket, original, code )
  end
end

end
