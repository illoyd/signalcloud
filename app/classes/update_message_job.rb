##
# Update an SMS message based upon the Twilio callback.
# Requires the following items
#   +callback_values+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# This class is intended for use with Delayed::Job.
#
class UpdateMessageJob < Struct.new( :callback_values, :quiet )

  cattr_accessor :logger

  self.logger = if defined?(Rails)
    Rails.logger
  elsif defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER
  end

  def perform
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
  
  def say(text, level = Logger::INFO)
    text = "[SendChallengeJob(#{self.ticket_id})] #{text}"
    puts text unless self.quiet
    self.logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if self.logger
  end

end
