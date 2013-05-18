##
# Produce a new invoice for the given organization.
# Requires the following items
#   +organization_id+: the organization ID to process
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Delayed::Job.
#
class CreateInvoiceJob < Struct.new( :organization_id, :next_invoice_at )
  include Talkable

  def perform
    organization = Organizations.find( organization_id )
    organization.create_invoice( next_invoice_at.end_of_day )
    organization.save!
  end

  alias :run :perform

end
