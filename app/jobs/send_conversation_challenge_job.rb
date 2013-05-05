##
# Send an SMS Challenge
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendConversationChallengeJob < Struct.new( :conversation_id, :force_resend )
  include Talkable

  def perform
    say( 'Sending challenge message.', Logger::DEBUG )
    begin
      messages = self.conversation.send_challenge_message!()
      say( 'Sent challenge message (Twilio: %s).' % [messages.first.twilio_sid] )
      
      # Create and enqueue a new expiration job
      JobTools.enqueue ExpireConversationJob.new( self.conversation.id, self.force_resend ), run_at: self.conversation.expires_at

    rescue SignalCloud::ChallengeAlreadySentError => ex
     say( 'Skipping as challenge message has already been sent.', Logger::DEBUG )
    
    rescue SignalCloud::MessageSendingError => ex
     say( ex.message, Logger::WARN )
    
    rescue => ex
      say( 'FAILED to send challenge message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end

  end
  
  def conversation
    @conversation ||= Conversation.find( self.conversation_id )
  end
  
  alias :run :perform

end