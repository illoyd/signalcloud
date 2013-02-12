##
# Send an SMS Reply
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendReplyJob < Struct.new( :ticket_id, :force_resend )
  include Talkable

  def perform
    say( 'Sending reply message.', Logger::DEBUG )
    begin
      messages = ticket.send_reply_message!()
      say( 'Sent reply message (Twilio: %s).' % [messages.first.twilio_sid] )




    rescue Ticketplease::ReplyAlreadySentError => ex
     say( 'Skipping as reply message has already been sent.', Logger::DEBUG )
    
    rescue Ticketplease::MessageSendingError => ex
     say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send reply message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end

  end
  
  def ticket
    @ticket ||= Ticket.find( self.ticket_id )
  end

  alias :run :perform

end
