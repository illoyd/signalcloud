##
# Produce a new invoice for the given organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Sidekiq.
#
class CreateInvoiceJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform( organization_id, next_invoice_at )
    organization = Organizations.find( organization_id )
    organization.create_invoice( next_invoice_at.end_of_day )
    organization.save!
  end

  alias :run :perform

end
