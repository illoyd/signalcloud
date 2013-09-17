##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Delayed::Job.
#
class UpgradeOrganizationJob < Struct.new( :organization_id )
  include Talkable

  def perform
  end
  
  def organization
    @organization ||= Organization.find(self.organization_id)
  end
  
  def priority
    Jobs::LOW
  end
  
end
