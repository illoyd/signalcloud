##
# Handle inbound SMS messages by finding the associated ticket and processing.
# Requires the following items
#   +message_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class InboundMessageJob < Struct.new( :message_values )
  include Talkable

  def perform
    self.standardise_message_values!
    
    # Get all applicable tickets. If none found, this is an 'unsolicited message'.
    if self.is_unsolicited_message?
      self.record_unsolicited_message
      self.send_reply_to_unsolicited_message if self.internal_phone_number.should_reply_to_unsolicited_sms?
    else
      self.handle_response_to_ticket()
    end
  end

  def is_unsolicited_message?
    self.applicable_tickets.empty?
  end
  
  def record_unsolicited_message()
    message_status = self.internal_phone_number.account.twilio_account.sms.messages.get( self.message_values[:sms_sid] )
    ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_NARRATIVE, price: message_status.price, notes: self.message_values.to_property_hash )
  end

  def send_reply_to_unsolicited_message()
    message_status = self.internal_phone_number.account.send_sms( self.message_values[:from], self.message_values[:to], self.internal_phone_number.unsolicited_sms_message )
    ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_REPLY_NARRATIVE, price: message_status.price, notes: self.message_values )
  end






  def handle_response_to_ticket()
    ticket = self.applicable_tickets.first
    self.add_message_to_ticket(ticket)
    self.update_ticket(ticket)
    ticket.send_reply_message!()
  end
  
  def internal_phone_number
    normalized_to_number = Ticket.normalize_phone_number self.message_values[:to]
    @phone_number ||= PhoneNumber.where( encrypted_to_number: Ticket.encrypt( :to_number, normalized_from_number ) ).first
  end
  
  ##  
  # Intuit the appropriate ticket based upon the TO and FROM.
  # In this situation, we SWAP the given TO and FROM, as this is a reply from the user. Tickets are always from: ticketplease, to: the recepient.
  def applicable_tickets()
    normalized_to_number = Ticket.normalize_phone_number self.message_values[:to]
    normalized_from_number = Ticket.normalize_phone_number self.message_values[:from]
    @applicable_tickets ||= Ticket.where({
      encrypted_to_number: Ticket.encrypt( :to_number, normalized_from_number ),
      encrypted_from_number: Ticket.encrypt( :from_number, normalized_to_number ),
      status: Ticket::CHALLENGE_SENT
      })
  end
  
  ##
  # Update the ticket...
  def update_ticket( ticket )
    ticket.response_received = DateTime.now
    
    # Update the ticket based upon the given value
    ticket.status = case Ticket.normalize_message(self.message_values[:body])
      when ticket.normalized_expe
      cted_confirmed_answer
        Ticket::CONFIRMED
      when ticket.normalized_expected_denied_answer
        Ticket::DENIED
      else
        Ticket::FAILED
    end
  end
  
  def add_message_to_ticket( ticket )
    message = ticket.messages.build( twilio_sid: self.message_values[:sms_sid], message_kind: Message::REPLY, payload: self.message_values )
    pp message.twilio_status.to_property_hash
    message.callback_payload = message.twilio_status.to_property_hash unless message.has_provider_price?
    message.save!
  end

  ##
  # Standardise the callback values by converting to a string, stripping, and underscoring.
  def standardise_message_values( values=nil )
    values = self.message_values.dup if values.nil?
    standardised = HashWithIndifferentAccess.new
    values.each { |key,value| standardised[key.to_s.strip.underscore] = value }
    return standardised
  end
  
  def standardise_message_values!()
    self.message_values = self.standardise_message_values( self.message_values )
  end

  alias :run :perform

end
