##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class UpgradeOrganizationJob < Struct.new( :organization_id )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform
  end
  
  def organization
    @organization ||= Organization.find(self.organization_id)
  end
  
end
