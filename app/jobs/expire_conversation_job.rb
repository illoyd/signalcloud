##
# Send an SMS Challenge
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#
# This class is intended for use with Sidekiq.
#
class ExpireConversationJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( conversation_id, force_send=false )
    # Get the conversation
    conversation = self.find_conversation(conversation_id)
    
    # If the conversation is not found or is closed, short-circuit and stop
    return true if conversation.nil? or conversation.is_closed?
    
    # Retry expiration later if conversation has not expired
    if conversation.is_open? and !conversation.is_expired?
      logger.info{ 'Conversation not expired; enqueueing new expire job.' }
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id ) 
      return true
    end

    # Expire the bloody conversation

    # Send the expiration SMS if not already sent.
    # This will automatically create the associated message
    logger.debug{ 'Attempting to expire conversation.' }
    begin
      messages = conversation.expire!
      logger.info{ 'Sent expiration message (Twilio: %s).' % [messages.first.twilio_sid] }

    rescue SignalCloud::ReplyAlreadySentError => ex
      logger.info{ 'Skipping as message has already been sent.' }
    
    rescue SignalCloud::MessageSendingError => ex
      logger.warn{ ex.message }
    
    rescue => ex
      logger.error{ 'FAILED to send message: %s.' % [ex.message] }
      raise ex

    end
  end
  
  alias :run :perform

  protected

  def find_conversation(conversation_id)
    return Conversation.where( id: conversation_id, status: Conversation::OPEN_STATUSES ).first
  end
  
end
