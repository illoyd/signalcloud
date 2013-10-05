##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class UpdateRemoteCommunicationGatewayJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform( communication_gateway_id )
    gateway = CommunicationGateway.find(communication_gateway_id)

    gateway.with_lock do
      return true unless gateway.can_update_remote?
      gateway.update_remote!
      gateway.save!
    end
  end
  
end
