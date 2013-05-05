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

  def perform
    # First, standardise callback values into 'underscored' formats
    self.standardise_callback_values!
    
    # Get the original message and update
    message = Message.find_by_twilio_sid!( self.callback_values[:sms_sid] )

    # If the status data does not contain all the needed data, query it
    self.callback_values.merge!( message.twilio_status.to_property_hash ) if self.requires_requerying_sms_status?
    self.standardise_callback_values!
    
    # Attach the callback payload
    message.provider_update = self.callback_values

    # Update the message's status
    message.status = self.translate_twilio_sms_status(self.callback_values[:sms_status])
    message.sent_at = self.callback_values.fetch(:date_sent, nil)
    
    # Update price if available
    if self.callback_values.include? :price and !self.callback_values[:price].nil?
      message.provider_cost = self.callback_values[:price].to_f
      message.save!
      #message.our_cost = message.conversation.stencil.account.account_plan.calculate_outbound_sms_cost( message.provider_cost )

      # Update the ledger_entry
      #ledger_entry = message.ledger_entry
      #ledger_entry.value = message.cost
      date_sent = self.callback_values.fetch(:date_sent, nil)
      date_sent = DateTime.now if date_sent.blank?
      date_sent = DateTime.parse( date_sent ) if date_sent.is_a?( String )
      # date_sent = date_sent.blank? ? DateTime.now : DateTime.parse( date_sent )
      message.ledger_entry.settled_at = date_sent
    end
    
    # Save as a db transaction
    message.save!
    message.ledger_entry.save!
    
    # Check and close the conversation's phase if appropriate
    conversation = message.conversation
    case message.message_kind
      when Message::CHALLENGE
        unless conversation.has_outstanding_challenge_messages?
          conversation.challenge_sent_at = self.callback_values[:date_sent]
          conversation.challenge_status = Message::SENT
          conversation.status = Conversation::CHALLENGE_SENT unless conversation.is_closed?
        else
          conversation.challenge_status = Message::SENDING
          conversation.status = Conversation::QUEUED unless conversation.is_closed?
        end 
      when Message::REPLY
        unless conversation.has_outstanding_reply_messages?
          conversation.reply_sent_at = self.callback_values[:date_sent]
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
