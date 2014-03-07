##
# Send an SMS Challenge
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Sidekiq.
#
class SendConversationChallengeJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( conversation_id )
    conversation = Conversation.find( conversation_id )
    message = nil
    
    # Skip if unable to send
    unless conversation.can_ask?
      logger.debug{ 'Skipping as challenge message has already been sent.' }
      return true
    end
    
    # Continue
    logger.debug{ 'Sending challenge message.' }
    begin
      message = conversation.ask!
      conversation.save!
      logger.info{ 'Sent challenge message (Provider: %s).' % [messages.provider_sid] }
      
      # Create and enqueue a new expiration job
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id )

    rescue SignalCloud::ChallengeAlreadySentError => ex
      logger.debug{ 'Skipping as challenge message has already been sent.' }
    
    rescue SignalCloud::MessageError => ex
      logger.warn{ ex.message }
      ex.conversation_message.error!
      # ex.conversation_message.save!
      conversation.error!
    
    rescue => ex
      logger.error{ 'FAILED to send challenge message: %s.' % [ex.message] }
#       message = conversation.messages.challenges.order('created_at').last
#       ex.conversation_message.error!
#       ex.conversation_message.save!
#       conversation.error!
      raise ex
    
    ensure
      conversation.save

    end

  end

  alias :run :perform

end
