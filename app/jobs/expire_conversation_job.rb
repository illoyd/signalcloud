##
# Send an SMS Challenge
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Sidekiq.
#
class ExpireConversationJob < Struct.new( :conversation_id, :force_resend )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform
    # Get the conversation
    conversation = self.find_conversation()
    
    # If the conversation is closed, short-circuit and stop
    return true if conversation.is_closed?
    
    # Retry expiration later if conversation has not expired
    # say( 'Conversation is open? %s and is expired? %s' % [ conversation.is_open?, conversation.expires_at <= DateTime.now ] )
    if conversation.is_open? and !conversation.is_expired?
      say( 'Conversation not expired; enqueueing new expire job.', Logger::DEBUG )
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id ) 
      return true
    end

    # Set conversation to expired
    conversation.status = Conversation::EXPIRED
    conversation.save
    
    # Send the expiration SMS if not already sent.
    # This will automatically create the associated message
    say( 'Attempting to send expiration message.', Logger::DEBUG )
    begin
      messages = conversation.send_reply_message!()
      say( 'Sent expiration message (Twilio: %s).' % [messages.first.twilio_sid] )

    rescue SignalCloud::ReplyAlreadySentError => ex
      say( 'Skipping as message has already been sent.', Logger::DEBUG )
    
    rescue SignalCloud::MessageSendingError => ex
      say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end
  end
  
  def find_conversation()
    return Conversation.find( self.conversation_id )
  end
  
  def force_resend?
    self.force_resend || false
  end
  
  alias :run :perform

end
