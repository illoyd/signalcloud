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

    # Lock conversation in a big arse transaction
    conversation = Conversation.find( conversation_id )
    conversation.with_lock do
      # Skip if unable to send
      unless conversation.can_ask?
        logger.debug{ 'Skipping as challenge message has already been sent.' }
        return true
      end
  
      # Continue
      logger.debug{ 'Sending challenge message.' }

      # Ask and save
      conversation.ask!
      conversation.save!
      logger.info{ 'Sent challenge message (First: %s).' % [conversation.messages.challenges.first.provider_sid] }
      
      # Create and enqueue a new expiration job
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id )
    end # End lock

    rescue SignalCloud::ChallengeAlreadySentError => ex
      logger.debug{ 'Skipping as challenge message has already been sent.' }
    
    rescue SignalCloud::MessageError => ex
      logger.warn{ ex.message }
      ex.conversation_message.save
      ex.conversation_message.error!
      conversation.error!
      conversation.save!
    
    rescue => ex
      logger.error{ 'FAILED to send challenge message: %s.' % [ex.message] }
      ex.conversation_message.save
      ex.conversation_message.error!
      conversation.error!
      conversation.save!
      raise ex

  end

  alias :run :perform

end
