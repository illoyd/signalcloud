##
# Send an SMS Challenge
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class ExpireTicketJob < Struct.new( :ticket_id, :force_resend, :quiet )
  include Talkable

  def perform
    # Get the ticket
    ticket = self.find_ticket()
    
    # Abort if ticket has already been closed AND this is not a forced resend
    if ticket.is_closed? && !self.force_resend?
      say( 'Skipping as ticket has already been closed.' )
      return true
    end
    
    # Set ticket to expired
    ticket.status = Ticket::EXPIRED
    ticket.save
    
    # Send the expiration SMS if not already sent.
    # This will automatically create the associated message
    say( 'Sending expiration message.' )
    begin
      message = ticket.send_reply_message()
      ticket.reply_sent = DateTime.now
      ticket.save

      # Create a 'pending' ledger_entry
      ticket.appliance.account.ledger_entries.create({
        item: message,
        narrative: 'Outbound SMS'
      }) 
    
      say( 'Twilio ID: %s, status: %s' % [message.twilio_sid, message.status] )
    rescue => ex
      say( 'FAILED to send expiration message: %s; %s.' % [ex.message, message.payload], Logger::ERROR )
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
