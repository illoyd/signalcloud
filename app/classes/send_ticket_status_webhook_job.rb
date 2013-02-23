##
# Send ticket status webhook update.
# Requires the following items
#   +phone_number_id+: the unique identifier for the phone number
#   +customer_number+: the customer's mobile number
#
# This class is intended for use with Delayed::Job.
#
class SendTicketStatusWebhookJob < Struct.new( :ticket_id )
  include Talkable

  def perform
    # TODO
  end
  
  alias :run :perform

end
