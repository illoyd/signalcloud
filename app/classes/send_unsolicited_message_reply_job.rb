##
# Send an unsolicited message reply.
# Requires the following items
#   +phone_number_id+: the unique identifier for the phone number
#   +customer_number+: the customer's mobile number
#
# This class is intended for use with Sidekiq.
#
class SendUnsolicitedMessageReplyJob < Struct.new( :phone_number_id, :customer_number )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform
    # TODO
  end
  
  alias :run :perform

end
