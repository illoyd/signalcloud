##
# Produce a new invoice for the given organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Sidekiq.
#
class UpdateRemotePhoneNumberJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform( phone_number_id )
    phone_number = PhoneNumber.where( id: phone_number_id, workflow_state: :active ).first
    return true if phone_number.nil?
    
    # Update phone number
    phone_number.with_lock do
      return true unless phone_number.can_refresh?
      phone_number.refresh!
      phone_number.save!
    end
  end

  alias :run :perform

end
