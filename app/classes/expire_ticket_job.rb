##
# Send an SMS Challenge
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class ExpireTicketJob < Struct.new( :ticket_id, :force_resend )
  include Talkable

  def perform
    # Get the ticket
    ticket = self.find_ticket()
    
    # If the ticket is closed, short-circuit and stop
    return true if ticket.is_closed?
    
    # Retry expiration later if ticket has not expired
    # say( 'Ticket is open? %s and is expired? %s' % [ ticket.is_open?, ticket.expiry <= DateTime.now ] )
    if ticket.is_open? and !ticket.is_expired?
      say( 'Ticket not expired; enqueueing new expire job.', Logger::DEBUG )
      Delayed::Job.enqueue ExpireTicketJob.new( ticket.id ), run_at: ticket.expiry
      return true
    end

    # Set ticket to expired
    ticket.status = Ticket::EXPIRED
    ticket.save
    
    # Send the expiration SMS if not already sent.
    # This will automatically create the associated message
    say( 'Attempting to send expiration message.', Logger::DEBUG )
    begin
      messages = ticket.send_reply_message!()
      say( 'Sent expiration message (Twilio: %s).' % [messages.first.twilio_sid] )

    rescue Ticketplease::ReplyAlreadySentError => ex
     say( 'Skipping as message has already been sent.', Logger::DEBUG )
    
    rescue Ticketplease::MessageSendingError => ex
     say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end
  end
  
  def find_ticket()
    return Ticket.find( self.ticket_id )
  end
  
  def force_resend?
    self.force_resend || false
  end
  
end
