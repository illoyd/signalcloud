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
  
  def perform( provider_sid, message_status, sent_at=nil )
    # sms = Twilio::InboundSms.new( callback_values )
    message = Message.find_by_provider_sid!( provider_sid )
    message_status = ActiveSupport::StringInquirer.new( message_status )

    # If we are missing a price, try to requery for it
    # sms = message.twilio_status.to_property_smash if ( sms.price.nil? and sms.message_status == Message::SENT )
    # sms = message.provider_status
    
    # Update the message
    # message.provider_update = callback_values
    message.provider_update = { sid: provider_sid, status: message_status, sent_at: sent_at }
    # message.segments = sms.segments unless sms.try(:segments).blank?
    
    # Update price if available
#     unless sms.price.nil?
#       message.cost = sms.price
#       message.ledger_entry.settled_at = sms.sent_at || DateTime.now
#     end

    # Shift message state
    case
      when message_status.sent?
        message.confirm!( sent_at ) if message.can_confirm?
        transition_conversation( message.conversation )
      
      when message_status.sending?
        # Do nothing
      
      when message_status.queued?
        # Do nothing
      
      when message_status.received?
        # Uh, what? Shouldn't happen...
      
      when message_status.failed?
        message.fail!( sent_at )
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