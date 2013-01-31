##
# Update an SMS message based upon the Twilio callback.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class UpdateMessageStatusJob < Struct.new( :callback_values, :quiet )
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
    self.callback_values.merge!( message.twilio_status ) if self.requires_requerying_sms_status?
    
    # Update the message
    message.provider_cost = self.callback_values[:price]
    message.our_cost = message.ticket.appliance.account.account_plan.calculate_outbound_sms_cost( message.provider_cost )
    message.callback_payload = self.callback_values
    
    case self.callback_values[:sms_status]
      when SMS_STATUS_SENT
        message.status = Message::SENT
        message.sent_at = self.callback_values[:date_sent]
      when SMS_STATUS_SENDING
        message.status = Message::SENDING
      when SMS_STATUS_QUEUED
        message.status = Message::QUEUED
    end
    
    # Update the ledger_entry
    ledger_entry = message.ledger_entry
    ledger_entry.value = message.cost
    ledger_entry.settled_at = self.callback_values[:date_sent] #if [SMS_STATUS_SENT, SMS_STATUS_QUEUED].include? message.status

    # Save as a db ledger_entry
    message.save!
    
    # Check and close the ticket's phase if appropriate
    ticket = message.ticket
    case message.message_kind
      when Message::CHALLENGE
        unless ticket.has_outstanding_challenge_messages?
          ticket.challenge_sent = self.callback_values[:date_sent]
          ticket.challenge_status = Message::SENT
        else
          ticket.challenge_status = Message::SENDING
        end 
      when Message::REPLY
        unless ticket.has_outstanding_reply_messages?
          ticket.reply_sent = self.callback_values[:date_sent]
          ticket.reply_status = Message::SENT
        else
          ticket.reply_status = Message::SENDING
        end
    end
    ticket.save!
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

end
