##
# Send ticket status webhook update.
# Requires the following items
#   +phone_number_id+: the unique identifier for the phone number
#   +customer_number+: the customer's mobile number
#
# This class is intended for use with Delayed::Job.
#
class SendTicketStatusWebhookJob < Struct.new( :ticket_id, :webhook_data )
  include Talkable

  def perform
    raise SignalCloudError.new 'Missing webhook data' if self.webhook_data.blank?
    ticket = Ticket.find self.ticket_id
    raise SignalCloudError.new('Ticket (%s) does not have a Webhook URI.' % [ ticket.id ]) if ticket.webhook_uri.blank?
    HTTParty.post ticket.webhook_uri, query: self.webhook_data
  end
  
  alias :run :perform

end
