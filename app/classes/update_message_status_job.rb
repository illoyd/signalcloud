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

  def perform
    # First, standardise callback values into 'underscored' formats
    self.standardise_callback_values!
    
    # Get the original message and update
    message = Message.find_by_twilio_sid!( self.callback_values[:sms_sid] )

    # If the status data does not contain all the needed data, query it, 
    status = message.twilio_status if self.requires_requerying_status?
    
    # Update the message
    message.provider_cost = self.callback_values[:price]
    message.our_cost = message.ticket.appliance.account.account_plan.calculate_outbound_sms_cost( message.provider_cost )
    message.callback_payload = self.callback_values
    
    case self.callback_values[:sms_status]
      when 'sent'
        message.status = Message::SENT
        message.sent_at = self.callback_values[:date_sent]
      when 'sending'
        message.status = Message::SENDING
      when 'queued'
        message.status = Message::QUEUED
    end
    
    # Update the transaction
    transaction = message.transaction
    transaction.value = message.cost
    transaction.settled_at = self.callback_values[:date_sent]

    # Save as a db transaction
    message.save!
    #transaction.save!
    
    # Check and close the ticket's phase if appropriate
    ticket = message.ticket
    case message.kind
      when Message::CHALLENGE
        unless ticket.has_outstanding_challenge_messages?
          ticket.challenge_sent = self.callback_values[:date_sent]
          ticket.challenge_status = Message::SENT
        end 
      when Message::REPLY
        unless ticket.has_outstanding_reply_messages?
          ticket.reply_sent = self.callback_values[:date_sent]
          ticket.reply_status = Message::SENT
        end
    end
    ticket.save
  end
  
  ##
  # If any key is missing from the cached callback values, we need to requery
  def requires_requerying_status?( values=nil )
    values = self.callback_values if values.nil?
    values = self.standardise_callback_values( values ) unless values.instance_of?( HashWithIndifferentAccess )
    return !( REQUIRED_KEYS - values.keys.map{ |key| key.to_sym } ).empty?
  end
  
  ##
  # Standardise the callback values by converting to a string, stripping, and underscoring.
  def standardise_callback_values( values=nil )
    values = self.callback_values if values.nil?
    standardised = HashWithIndifferentAccess.new
    values.each { |key,value| standardised[key.to_s.strip.underscore] = value }
    return standardised
  end
  
  def standardise_callback_values!()
    self.callback_values = self.standardise_callback_values( self.callback_values )
  end

end
