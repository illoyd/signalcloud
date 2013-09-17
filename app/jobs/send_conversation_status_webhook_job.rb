##
# Send conversation status webhook update.
# Requires the following items
#   +phone_number_id+: the unique identifier for the phone number
#   +customer_number+: the customer's mobile number
#
# This class is intended for use with Sidekiq.
#
class SendConversationStatusWebhookJob < Struct.new( :conversation_id, :webhook_data )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform
    raise SignalCloudError.new 'Missing webhook data' if self.webhook_data.blank?
    conversation = Conversation.find self.conversation_id
    raise SignalCloudError.new('Conversation (%s) does not have a Webhook URI.' % [ conversation.id ]) if conversation.webhook_uri.blank?
    HTTParty.post conversation.webhook_uri, query: self.webhook_data
  end
  
  alias :run :perform

end
