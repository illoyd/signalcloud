##
# Send an SMS Challenge
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendChallengeJob < Struct.new( :ticket_id, :force_resend, :quiet )
  include Talkable

  def perform
    # Get the ticket
    ticket = self.find_ticket()
    
    # Send the SMS if not already sent
    # This will automatically create the message
    say( 'Sending initial challenge message.' )
    begin
      messages = ticket.send_challenge_message!()
      say( 'Received response %s.' % [messages.first.twilio_sid] )
      
      # Create and enqueue a new expiration job
      Delayed::Job.enqueue ExpireTicketJob.new( ticket.id, false, self.quiet ), run_at: ticket.expiry

    #rescue Ticketplease::ChallengeAlreadySentError => ex
    #  say( 'Skipping as message has already been sent.' )
    
    #rescue Ticketplease::MessageSendingError => ex
    #  say( ex.message, Logger::WARN )
    
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
