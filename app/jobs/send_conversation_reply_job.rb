##
# Send an SMS Reply to an open Conversation.
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendConversationReplyJob < Struct.new( :conversation_id, :force_resend )
  include Talkable

  def perform
    say( 'Sending reply message.', Logger::DEBUG )
    begin
      messages = conversation.send_reply_message!()
      say( 'Sent reply message (Twilio: %s).' % [messages.first.twilio_sid] )




    rescue SignalCloud::ReplyAlreadySentError => ex
     say( 'Skipping as reply message has already been sent.', Logger::DEBUG )
    
    rescue SignalCloud::MessageSendingError => ex
     say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send reply message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end

  end
  
  def conversation
    @conversation ||= Conversation.find( self.conversation_id )
  end

  alias :run :perform

end
