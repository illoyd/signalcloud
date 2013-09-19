##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class UpgradeOrganizationJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform( organization_id )
    organization = Organization.find(organization_id)
  end
  
end
