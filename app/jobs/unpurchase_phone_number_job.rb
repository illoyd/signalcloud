##
# Release the provided phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class UnpurchasePhoneNumberJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform( phone_number_id )
    phone_number = PhoneNumber.find(phone_number_id)

    # Silently skip if already inactive
    return true if phone_number.inactive?
    
    # Perform actual release command. This will reach out to the provider and release the number.
    phone_number.unpurchase!
  end
  
end
