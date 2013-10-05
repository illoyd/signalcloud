##
# Produce a new invoice for the given organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Sidekiq.
#
class UpdateRemotePhoneNumbersJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform()
    PhoneNumber.where( workflow_state: :active ).where( 'updated_remote_at is null or updated_remote_at <= ?', 1.week.ago ).pluck(:id).each do |phone_number_id|
      UpdateRemotePhoneNumberJob.new.perform( phone_number_id )
      # "Would enqueue #{phone_number_id}"
    end
  end

  alias :run :perform

end
