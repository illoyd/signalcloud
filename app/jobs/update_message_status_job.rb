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
  
  #REQUIRED_KEYS = [ :sms_sid, :price, :sms_status, :date_sent ]
  
  #SMS_STATUS_SENT = 'sent'
  #SMS_STATUS_SENDING = 'sending'
  #SMS_STATUS_QUEUED = 'queued'
  
  def perform( callback_values )
    sms = Twilio::InboundSms.new( callback_values )
    message = Message.find_by_provider_sid!( sms.sid )

    # If we are missing a price, try to requery for it
    # sms = message.twilio_status.to_property_smash if ( sms.price.nil? and sms.message_status == Message::SENT )
    
    # Update the message
    message.provider_update = callback_values
    
    # Update price if available
    unless sms.price.nil?
      message.provider_cost = sms.price
      message.ledger_entry.settled_at = sms.sent_at || DateTime.now
    end

    # Shift message state
    case
      when sms.sent?
        message.confirm!( sms.sent_at )
        transition_conversation( message.conversation )
      
      when sms.sending?
        # Do nothing
      
      when sms.queued?
        # Do nothing
      
      when sms.received?
        # Uh, what? Shouldn't happen...
      
      when sms.failed?
        message.fail!( sms.sent_at )
        message.conversation.error!
      
      else
        # This should never happen, so that means something's gone wrong!
        # TODO raise an event or log!
    end

    # Save as a db transaction
    message.save!
    message.conversation.save!
  end
    
  alias :run :perform
  
  def transition_conversation( conversation )
    case
      when conversation.can_asked?
        conversation.asked!
      when conversation.can_confirmed?
        conversation.confirmed!
      when conversation.can_denied?
        conversation.denied!
      when conversation.can_failed?
        conversation.failed!
      when conversation.can_expired?
        conversation.expired!
    end
  end

end