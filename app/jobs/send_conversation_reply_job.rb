##
# Send an SMS Reply to an open Conversation.
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Sidekiq.
#
class SendConversationReplyJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( conversation_id, force_resend=false )
    conversation ||= Conversation.find( conversation_id )

    logger.debug{ 'Sending reply message.' }
    begin
      messages = conversation.send_reply_message!()
      logger.info{ 'Sent reply message (Twilio: %s).' % [messages.first.twilio_sid] }

    rescue SignalCloud::ReplyAlreadySentError => ex
     logger.debug{ 'Skipping as reply message has already been sent.' }
    
    rescue SignalCloud::MessageSendingError => ex
     logger.warn{ ex.message }
    
    rescue => ex
      logger.error{ 'FAILED to send reply message: %s.' % [ex.message] }
      raise ex

    end

  end
  
  alias :run :perform

end
