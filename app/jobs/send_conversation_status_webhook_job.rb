##
# Send conversation status webhook update.
# Requires the following items
#   +phone_number_id+: the unique identifier for the phone number
#   +customer_number+: the customer's mobile number
#
# This class is intended for use with Sidekiq.
#
class SendConversationStatusWebhookJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( conversation_id, webhook_data )
    raise SignalCloudError.new 'Missing webhook data' if webhook_data.blank?
    conversation = Conversation.find conversation_id
    raise SignalCloudError.new('Conversation (%s) does not have a Webhook URI.' % [ conversation.id ]) if conversation.webhook_uri.blank?
    HTTParty.post conversation.webhook_uri, body: webhook_data
  end
  
  alias :run :perform

end
