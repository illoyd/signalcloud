##
# Handle inbound SMS messages by finding the associated ticket and processing.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class InboundMessageJob < Struct.new( :callback_values )
  include Talkable

  def perform
    
    # For each ticket, test and update
    self.applicable_tickets.each { |ticket| self.update_ticket ticket }

    # Get the original message and update
    message = Message.find_by_twilio_sid( callback_values[:sid] )
    message.payload = callback_values

    if callback_values.include? :price and !callback_values[:price].nil?    
      message.provider_cost = callback_values[:price]
      message.our_cost = message.ticket.account.account_plan.calculate_cost( message.provider_cost )
      message.ledger_entry.cost = message.cost
    end

    message.save!
  end

  ##  
  # Intuit the appropriate ticket based upon the TO and FROM.
  # In this situation, we SWAP the given TO and FROM, as this is a reply from the user. Tickets are always from: ticketplease, to: the recepient.
  def applicable_tickets()
    normalized_to_number = Ticket.normalize_phone_number self.callback_values[:to]
    normalized_from_number = Ticket.normalize_phone_number self.callback_values[:from]
    tickets = Ticket.where({
      encrypted_to_number: Ticket.encrypt( :to_number, normalized_from_number ),
      encrypted_from_number: Ticket.encrypt( :from_number, normalized_to_number ),
      status: Ticket::CHALLENGE_SENT
      })
  end
  
  def update_ticket( ticket )
    # Update
    ticket.reply_received = DateTime.now
    
    # Update the ticket based upon the given value
    ticket.status = case Ticket.normalize_message(self.callback_values[:body])
      when ticket.normalized_expected_confirmed_answer
        Ticket::CONFIRMED
      when ticket.normalized_expected_denied_answer
        Ticket::DENIED
      else
        Ticket::FAILED
      end
    
    # Save the ticket and send an outbound message
    # ticket.save
    ticket.send_reply_message!()
  end

end
