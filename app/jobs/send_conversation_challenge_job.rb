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

  def perform( conversation_id, force_resend=false )
    conversation ||= Conversation.find( conversation_id )

    logger.debug{ 'Sending challenge message.' }
    begin
      messages = conversation.send_challenge_message!()
      logger.info{ 'Sent challenge message (Twilio: %s).' % [messages.first.twilio_sid] }
      
      # Create and enqueue a new expiration job
      ExpireConversationJob.perform_at( conversation.expires_at, conversation.id, force_resend )

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
