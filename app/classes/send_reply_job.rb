##
# Send an SMS Reply
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendReplyJob < Struct.new( :ticket_id, :force_resend, :quiet )
  include Talkable

  def perform
    # Get the ticket
    ticket = self.find_ticket()
    
    # Send the expiration SMS if not already sent.
    # This will automatically create the associated message
    say( 'Attempting to send reply message.', Logger::DEBUG )
    begin
      messages = ticket.send_reply_message!()
      say( 'Sent reply message (Twilio: %s).' % [messages.first.twilio_sid] )

    rescue Ticketplease::ReplyAlreadySentError => ex
     say( 'Skipping as message has already been sent.' )
    
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
