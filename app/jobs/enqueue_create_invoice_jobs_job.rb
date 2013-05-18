##
# Prepare jobs to do the heavy lifting of creating new invoices for all organizations requiring invoices.
# Requires the following items
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Delayed::Job.
#
class EnqueueCreateInvoiceJobsJob < Struct.new( :next_invoice_at )
  include Talkable

  def perform
    next_invoice_at = next_invoice_at.end_of_day
    Organizations.where( 'next_invoice_at <= ?', next_invoice_at ).pluck( :id ) do |organization_id|
      Delayed::Job::enqueue CreateInvoiceJob.new( organization_id, next_invoice_at )
    end
  end

  alias :run :perform

end
