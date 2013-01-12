##
# Send an SMS Challenge
# Requires the following items
#   +ticket_id+: the unique identifier for the ticket
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Delayed::Job.
#
class SendChallengeJob < Struct.new( :ticket_id, :force_resend, :quiet )

  cattr_accessor :logger

    self.logger = if defined?(Rails)
      Rails.logger
    elsif defined?(RAILS_DEFAULT_LOGGER)
      RAILS_DEFAULT_LOGGER
    end

  def perform
    # Get the ticket
    ticket = self.find_ticket()
    
    # Send the SMS if not already sent
    # This will automatically create the message
    say( 'Sending initial challenge message.' )
    begin
      message = ticket.send_challenge_message()
      message.save!
      say( 'Received response %s.' % [message.twilio_sid] )
      
      # Create and enqueue a new expiration job
      DelayedJob::enqueue ExpireTicketJob.new( ticket.id, false, self.quiet )

    rescue Ticketplease::MessageAlreadySentError => ex
      say( 'Skipping as message has already been sent.' )
    
    rescue => ex
      say( 'FAILED to send message: %s.' % [ex.message], Logger::ERROR )
      raise ex

    end

  end
  
  def find_ticket()
    return Ticket.find( self.ticket_id )
  end
  
  def force_resend?
    self.force_resend || false
  end
  
#   def enqueue
#     Delayed::Job.enqueue self
#   end
  
  def say(text, level = Logger::INFO)
    text = "[SendChallengeJob(#{self.ticket_id})] #{text}"
    puts text unless self.quiet
    self.logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if self.logger
  end

end
