##
# Handle inbound SMS messages by finding the associated ticket and processing.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class InboundMessageJob < Struct.new( :callback_values, :quiet )
  include Talkable

  def perform
    # Intuit the appropriate ticket based upon the TO and FROM
    # In this situation, we SWAP the given TO and FROM, as this is a reply from the user
    # Tickets are always from: ticketplease, to: the recepient
    tickets = Ticket.find_all_by_to_number_and_from_number_and_status( self.callback_values[:from], self.callback_values[:to], Ticket::CHALLENGE_SENT )
    
    # For each ticket, test and update
    tickets.each { |ticket| self.update_ticket ticket }
    
  
    # Get the original message and update
    message = Message.find_by_twilio_sid( callback_values[:sid] )
    message.provider_cost = callback_values[:price]
    message.our_cost = message.ticket.account.account_plan.calculate_cost( message.provider_cost )
    message.payload = callback_values
    message.save!
    
    # Update the transaction
    transaction = message.transactions.find_by_twilio_sid( callback_values[:sid] )
    transaction.cost = message.cost
    transaction.save!
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
        Ticket::FAIELD
      end
    
    # Save the ticket and send an outbound message
    ticket.save
    ticket.send_reply_message()
  end

end
