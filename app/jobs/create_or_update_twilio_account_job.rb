##
# Create a new Twilio Organization for this organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#
# This class is intended for use with Sidekiq.
#
class CreateOrUpdateTwilioAccountJob < Struct.new( :organization_id )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform

    if self.communication_gateway.new?
      self.communication_gateway.create_remote!

    elsif self.communication_gateway.ready?
      self.communication_gateway.update_remote!

    else
      raise RuntimeError.new( "Communication Gateway for Org #{self.organization.id} is in an unrecognised state: #{self.organization.communication_gateway}." )
    end

    self.communication_gateway.save!
  end
  
  def organization
    @organization ||= Organization.find( organization_id )
  end
  
  def communication_gateway
    @communication_gateway ||= ( self.organization.communication_gateway || TwilioCommunicationGateway.new({ organization: self.organization }) )
  end
  
  alias :run :perform

end
