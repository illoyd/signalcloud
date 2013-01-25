##
# Produce a new invoice for the given account.
# Requires the following items
#   +account_id+: the account ID to process
#   +next_invoice_at+: process all invoices from this date
#
# This class is intended for use with Delayed::Job.
#
class CreateInvoiceJob < Struct.new( :account_id, :next_invoice_at )
  include Talkable

  def perform
    account = Accounts.find( account_id )
    account.create_invoice( next_invoice_at.end_of_day )
    account.save!
  end

end
