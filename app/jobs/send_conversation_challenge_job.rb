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

    logger.debug{ 'Sending challenge message.' }
    begin
      message = conversation.start!
      logger.info{ 'Sent challenge message (Provider: %s).' % [messages.provider_sid] }
      
      # Create and enqueue a new expiration job
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id )

    rescue SignalCloud::ChallengeAlreadySentError => ex
     logger.debug{ 'Skipping as challenge message has already been sent.' }
    
    rescue SignalCloud::MessageSendingError => ex
     logger.warn{ ex.message }
    
    rescue => ex
      logger.error{ 'FAILED to send challenge message: %s.' % [ex.message] }
      raise ex

    end

  end

  alias :run :perform

end
