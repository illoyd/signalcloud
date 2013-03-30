##
# Send an SMS Challenge
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendTicketChallengeJob < Struct.new( :ticket_id, :force_resend )
  include Talkable

  def perform
    say( 'Sending challenge message.', Logger::DEBUG )
    begin
      messages = self.ticket.send_challenge_message!()
      say( 'Sent challenge message (Twilio: %s).' % [messages.first.twilio_sid] )
      
      # Create and enqueue a new expiration job
      JobTools.enqueue ExpireTicketJob.new( self.ticket.id, self.force_resend ), run_at: self.ticket.expiry

    rescue SignalCloud::ChallengeAlreadySentError => ex
     say( 'Skipping as challenge message has already been sent.', Logger::DEBUG )
    
    rescue SignalCloud::MessageSendingError => ex
     say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send challenge message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end

  end
  
  def ticket
    @ticket ||= Ticket.find( self.ticket_id )
  end
  
  alias :run :perform

end
