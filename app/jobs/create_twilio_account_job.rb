##
# Create a new Twilio Organization for this organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#
# This class is intended for use with Delayed::Job.
#
class CreateTwilioAccountJob < Struct.new( :organization_id )
  include Talkable

  def perform
    self.organization.create_twilio_account
    self.organization.create_twilio_application
    self.organization.save!
  end
  
  def organization
    @organization ||= Organization.find( organization_id )
  end
  
  alias :run :perform

end
