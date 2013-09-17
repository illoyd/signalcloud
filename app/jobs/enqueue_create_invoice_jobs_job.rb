##
# Prepare jobs to do the heavy lifting of creating new invoices for all organizations requiring invoices.
# Requires the following items
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Sidekiq.
#
class EnqueueCreateInvoiceJobsJob < Struct.new( :next_invoice_at )
  include Talkable
  include Sidekiq::Worker
  sidekiq_options :queue => :background

  def perform
    next_invoice_at = next_invoice_at.end_of_day
    Organizations.where( 'next_invoice_at <= ?', next_invoice_at ).pluck( :id ) do |organization_id|
      CreateInvoiceJob.perform_async organization_id, next_invoice_at
    end
  end

  alias :run :perform

end
