##
# Update an SMS message based upon the Twilio callback.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class UpdateMessageStatusJob < Struct.new( :callback_values )
  include Talkable
  
  REQUIRED_KEYS = [ :sms_sid, :price, :sms_status, :date_sent ]
  
  SMS_STATUS_SENT = 'sent'
  SMS_STATUS_SENDING = 'sending'
  SMS_STATUS_QUEUED = 'queued'
  
  def sms
    @sms ||= Twilio::InboundSms.new( self.callback_values )
  end
  
  def sms=(value)
    @sms = value
  end

  def perform
    message = Message.find_by_twilio_sid!( sms.sms_sid )

    # If we are missing a price, try to requery for it
    self.sms = message.twilio_status.to_property_smash if ( sms.price.nil? and sms.message_status == Message::SENT )
    
    # Update the message
    message.provider_update = self.callback_values
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
          conversation.challenge_sent_at = sms.sent_at # self.callback_values[:date_sent]
          conversation.challenge_status = Message::SENT
          conversation.status = Conversation::CHALLENGE_SENT unless conversation.is_closed?
        else
          conversation.challenge_status = Message::SENDING
          conversation.status = Conversation::QUEUED unless conversation.is_closed?
        end 
      when Message::REPLY
        unless conversation.has_outstanding_reply_messages?
          conversation.reply_sent_at = sms.sent_at # self.callback_values[:date_sent]
          conversation.reply_status = Message::SENT
        else
          conversation.reply_status = Message::SENDING
        end
    end
    conversation.save!
  end
  
  ##
  # If any key is missing from the cached callback values, we need to requery
  def requires_requerying_sms_status?( values=nil )
    values = self.callback_values if values.nil?
    values = self.standardise_callback_values( values ) unless values.instance_of?( HashWithIndifferentAccess )
    return !( REQUIRED_KEYS - values.keys.map{ |key| key.to_sym } ).empty?
  end
  
  ##
  # Standardise the callback values by converting to a string, stripping, and underscoring.
  def standardise_callback_values( values=nil )
    values = self.callback_values.dup if values.nil?
    standardised = HashWithIndifferentAccess.new
    values.each { |key,value| standardised[key.to_s.strip.underscore] = value }
    return standardised
  end
  
  def standardise_callback_values!()
    self.callback_values = self.standardise_callback_values( self.callback_values )
  end
  
  def translate_twilio_sms_status( twilio_status )
    return case self.callback_values[:sms_status]
      when SMS_STATUS_SENT; Message::SENT
      when SMS_STATUS_SENDING; Message::SENDING
      when SMS_STATUS_QUEUED; Message::QUEUED
      else; nil
    end
  end
  
  alias :run :perform

end
