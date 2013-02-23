##
# Handle inbound SMS messages by finding the associated ticket and processing.
# Requires the following items
#   +provider_update+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# Generally +provider_update+ will include the following:
#   +SmsSid+:     A 34 character unique identifier for the message. May be used to later retrieve this message from the REST API.
#   +AccountSid+: The 34 character id of the Account this message is associated with.
#   +To+:         The phone number of the recipient.
#   +From+:       The phone number that sent this message.
#   +Body+:       The text body of the SMS message. Up to 160 characters long.
#
# The #normalize_provider_update command will normalise the values to 'underscored' names. For example, +SmsSid+ will become +sms_sid+.
#
# This class is intended for use with Delayed::Job.
#
class InboundMessageJob < Struct.new( :provider_update )
  include Talkable

  def perform
    self.normalize_provider_update!
    
    # Find all open tickets
    open_tickets = self.find_open_tickets()
    
    case open_tickets.count
      # No open tickets found; treat as an unsolicited message.
      when 0
        self.perform_unsolicited_action()
      
      # Only one ticket, so process immediately
      when 1
        self.perform_matching_ticket_action( open_tickets.first )

      # More than 1, so scan for possible positive or negative match.
      else
        self.perform_multiple_matching_tickets_action( open_tickets )
    end
  end
  
  def perform_unsolicited_action()
    self.internal_phone_number.record_unsolicited_message({
      customer_number: self.provider_update[:from],
      body: self.provider_update[:body],
      payload: self.provider_update
    })
    JobTools.enqueue SendUnsolicitedMessageReplyJob.new( self.internal_phone_number.id, self.provider_update[:from] )
  end
  
  def perform_matching_ticket_action( ticket )
    ticket.accept_answer! self.provider_update[:body]
    JobTools.enqueue SendTicketReplyJob.new ticket.id
    JobTools.enqueue SendTicketStatusWebhookJob.new ticket.id
  end
  
  def perform_multiple_matching_tickets_action( open_tickets )
    matching_ticket = open_tickets.first

    # Scan for possible applicable tickets
    open_tickets.each do |ticket|
      # If one is found, process it immediately and stop
      if ticket.answer_applies? self.provider_update[:body]
        matching_ticket = ticket
        break
      end
    end
    
    # Perform the 'normal' action
    self.perform_matching_ticket_action( matching_ticket )
  end
  
  ##
  # Process ticket!
#   def process_ticket( ticket )
#     ticket.process_answer! self.provider_update[:body]
#     JobTools.enqueue SendTicketReplyJob.new ticket.id
#     # TODO JobTools.enqueue SendTicketStatusWebhookJob.new ticket.id
#   end

  ##  
  # Intuit the appropriate ticket based upon the TO and FROM.
  # In this situation, we SWAP the given TO and FROM, as this is a reply from the user. Tickets are always from: ticketplease, to: the recepient.
  def find_open_tickets()
    self.normalize_provider_update!
    Ticket.find_open_tickets( self.provider_update[:to], self.provider_update[:from] ).order( 'challenge_sent' )
#     normalized_to_number = PhoneNumber.normalize_phone_number self.provider_update[:to]
#     normalized_from_number = PhoneNumber.normalize_phone_number self.provider_update[:from]
#     Ticket.where({
#       encrypted_to_number: Ticket.encrypt( :to_number, normalized_from_number ),
#       encrypted_from_number: Ticket.encrypt( :from_number, normalized_to_number ),
#       status: Ticket::CHALLENGE_SENT
#       }).order('challenge_sent')
  end
  
#   def handle_response_to_ticket()
#     ticket = self.find_open_tickets.first
#     self.add_message_to_ticket(ticket)
#     self.update_ticket(ticket)
#     ticket.send_reply_message!()
#   end

#   def is_unsolicited_message?
#     self.find_open_tickets.empty?
#   end
  
  def internal_phone_number
    self.normalize_provider_update!
    #normalized_to_number = PhoneNumber.normalize_phone_number self.provider_update[:to]
    #@phone_number ||= PhoneNumber.where( encrypted_number: PhoneNumber.encrypt( :number, normalized_to_number ) ).first
    PhoneNumber.find_by_number( self.provider_update[:to] ).first
  end
  




#   def record_unsolicited_message()
#     message_status = self.internal_phone_number.account.twilio_account.sms.messages.get( self.provider_update[:sms_sid] )
#     ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_NARRATIVE, price: message_status.price, notes: self.provider_update.to_property_hash )
#   end

#   def send_reply_to_unsolicited_message()
#     message_status = self.internal_phone_number.account.send_sms( self.provider_update[:from], self.provider_update[:to], self.internal_phone_number.unsolicited_sms_message )
#     ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_REPLY_NARRATIVE, price: message_status.price, notes: self.provider_update )
#   end






  
  
  ##
  # Update the ticket...
#   def update_ticket( ticket )
#     ticket.response_received = DateTime.now
#     
#     # Update the ticket based upon the given value
#     ticket.status = case Ticket.normalize_message(self.provider_update[:body])
#       when ticket.normalized_expected_confirmed_answer
#         Ticket::CONFIRMED
#       when ticket.normalized_expected_denied_answer
#         Ticket::DENIED
#       else
#         Ticket::FAILED
#     end
#   end
  
#   def add_message_to_ticket( ticket )
#     message = ticket.messages.build( twilio_sid: self.provider_update[:sms_sid], message_kind: Message::REPLY, payload: self.provider_update )
#     pp message.twilio_status.to_property_hash
#     message.callback_payload = message.twilio_status.to_property_hash unless message.has_provider_price?
#     message.save!
#   end

  ##
  # Standardise the callback values by converting to a string, stripping, and underscoring.
  def normalize_provider_update( values=nil )
    values = self.provider_update.dup if values.nil?
    standardised = HashWithIndifferentAccess.new
    values.each { |key,value| standardised[key.to_s.strip.underscore] = value }
    return standardised
  end
  
  def normalize_provider_update!()
    self.provider_update = self.normalize_provider_update( self.provider_update )
  end

  alias :run :perform

end
