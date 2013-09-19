##
# Update an SMS message based upon the Twilio callback.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#
# This class is intended for use with Sidekiq.
#
class UpdateMessageStatusJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default
  
  REQUIRED_KEYS = [ :sms_sid, :price, :sms_status, :date_sent ]
  
  SMS_STATUS_SENT = 'sent'
  SMS_STATUS_SENDING = 'sending'
  SMS_STATUS_QUEUED = 'queued'
  
  def perform( callback_values )
    sms = Twilio::InboundSms.new( callback_values )
    message = Message.find_by_twilio_sid!( sms.sms_sid )

    # If we are missing a price, try to requery for it
    sms = message.twilio_status.to_property_smash if ( sms.price.nil? and sms.message_status == Message::SENT )
    
    # Update the message
    message.provider_update = callback_values
    message.status = sms.message_status
    message.sent_at = sms.sent_at if ( sms.message_status == Message::SENT )
    
    # Update price if available
    unless sms.price.nil?
      message.provider_cost = sms.price
      message.ledger_entry.settled_at = sms.sent_at || DateTime.now
    end

    # Save as a db transaction
    message.save!
    message.ledger_entry.save! if message.ledger_entry
    
    # Check and close the conversation's phase if appropriate
    conversation = message.conversation
    case message.message_kind
      when Message::CHALLENGE
        unless conversation.has_outstanding_challenge_messages?
          conversation.challenge_sent_at = sms.sent_at
          conversation.challenge_status = Message::SENT
          conversation.status = Conversation::CHALLENGE_SENT unless conversation.is_closed?
        else
          conversation.challenge_status = Message::SENDING
          conversation.status = Conversation::QUEUED unless conversation.is_closed?
        end 
      when Message::REPLY
        unless conversation.has_outstanding_reply_messages?
          conversation.reply_sent_at = sms.sent_at
          conversation.reply_status = Message::SENT
        else
          conversation.reply_status = Message::SENDING
        end
    end
    conversation.save!
  end
    
  alias :run :perform

end
