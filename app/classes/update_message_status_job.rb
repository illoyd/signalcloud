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

  def perform
    # Get the original message and update
    message = self.find_message()
    message.provider_cost = self.callback_values[:price]
    message.our_cost = message.ticket.account.account_plan.calculate_cost( message.provider_cost )
    message.callback_payload = self.callback_values
    
    # Update the transaction
    transaction = message.transaction
    transaction.cost = message.cost
    transaction.settled_at = DateTime.now

    # Save as a db transaction
    message.save!
    transaction.save!
  end

  def find_message()
    return Message.find_by_twilio_sid!( self.callback_values[:sid] )
  end

end
