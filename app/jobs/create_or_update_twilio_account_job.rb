##
# Create a new Twilio Organization for this organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#
# This class is intended for use with Sidekiq.
#
class CreateOrUpdateTwilioAccountJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( organization_id )
  
    organization = Organization.find( organization_id )
    communication_gateway = ( organization.communication_gateway_for(:twilio) || TwilioCommunicationGateway.new({ organization: organization }) )

    if communication_gateway.new?
      communication_gateway.save!
      communication_gateway.create_remote!

    elsif communication_gateway.ready?
      communication_gateway.update_remote!

    else
      raise RuntimeError.new( "Communication Gateway for Org #{organization.id} is in an unrecognised state: #{organization.communication_gateway}." )
    end

    communication_gateway.save!
  end
  
  alias :run :perform

end
