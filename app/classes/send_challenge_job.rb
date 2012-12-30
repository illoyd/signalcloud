class SendChallengeJob < Struct.new( :ticket_id )

  def perform
    # Get the most recent copy of the ticket
    ticket = self.find_ticket()
    
    # Abort if ticket has already been sent
    return if ticket.has_challenge_been_sent?
    
    # Send the SMS if not already sent
    results = ticket.send_challenge()
    
    # Save the message for future access
    # This payload will, generally, be a subset of the complete payload
    # We'll update the message with the results of the 'sms delivered webhook' provided by Twilio
    #message = ticket.messages.create({
    #  twilio_sid: results['sid'],
    #  payload: results
    #})
  end
  
  def find_ticket()
    return Ticket.find( self.ticket_id )
  end
  
end