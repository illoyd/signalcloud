##
# Purchase the requested phone number.
# Requires the following items
#   +phone_number_id+: the ID of the phone number object
#
# This class is intended for use with Sidekiq.
#
class PurchasePhoneNumberJob < Struct.new( :phone_number_id )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform
    # Silently skip if already purchased and is active
    return true if self.phone_number.active?
    
    # Perform actual purchase command. This will reach out to the provider and purchase the number
    begin
      self.phone_number.purchase!
    
    rescue Twilio::Rest::RequestError => ex
      case ex.code
        when Twilio::ERR_PHONE_NUMBER_NOT_AVAILABLE
          self.phone_number.deactivate!
        else
          raise ex
      end
    end
  end
  
  def phone_number
    @phone_number ||= PhoneNumber.find(self.phone_number_id)
  end
  
end
