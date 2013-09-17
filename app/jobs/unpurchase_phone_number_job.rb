##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class UnpurchasePhoneNumberJob < Struct.new( :phone_number_id )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform
    # Silently skip if already inactive
    return true if self.phone_number.inactive?
    
    # Perform actual release command. This will reach out to the provider and release the number.
    self.phone_number.unpurchase!
  end
  
  def phone_number
    @phone_number ||= PhoneNumber.find(self.phone_number_id)
  end
  
end
