class Invoice < ActiveRecord::Base
  attr_accessible :freshbooks_id, :date_from, :date_to
  
  belongs_to :account, inverse_of: :invoices
  
  validates_presence_of :account_id, :date_from, :date_to
  
  ##
  # Does this invoice have an associated invoice in the finance system?
  def has_invoice?
    !self.freshbooks_id.nil?
  end

  ##
  # Automatically filter the available universe of ledger entries into this invoice's time period.
  def ledger_entries
    self.account.ledger_entries.where( 'ledger_entries.created_at >= ? and ledger_entries.created_at <= ?', self.date_from, self.date_to )
  end
  
  ##
  # Calculate the sum of all ledger entries for this invoice's period.
  # At the moment, this is not cached, so use it sparingly.
  def balance
    self.ledger_entries.sum(:value)
  end
  
  ##
  # Automaticaly create, save, and send the freshbook invoice.
  def create_and_send_freshbooks_invoice!
    self.create_freshbooks_invoice
    self.send_freshbooks_invoice!
  end
  
  ##
  # Send this invoice from the finance system.
  def send_freshbooks_invoice!
    raise Ticketplease::ClientInvoiceNotCreatedError.new unless self.has_invoice?
    Freshbooks.account.invoice.send_by_email( invoice_id: self.freshbooks_id )
    self.sent_at = DateTime.now
    self.save!
  end
  
  ##
  # Apply all credits for this period to the account.
  def apply_freshbooks_credits()
    self.ledger_entries.credits.select( 'narrative, sum(value) as value, created_at' ).group(:narrative).each do |entry|
      self.apply_freshbooks_credit( entry )
    end
  end
  
  ##
  # Apply a single credit to this invoice.
  def apply_freshbooks_credit( ledger_entry )
    response = Freshbooks.account.payment.create({
      invoice_id: self.freshbooks_id,
      client_id: self.account.freshbooks_id,
      amount: ledger_entry.value,
      date: ledger_entry.created_at,
      type: 'Credit',
      notes: ledger_entry.narrative
    })
  end
  
  ##
  # Create a single invoice in the financial system without saving.
  def create_freshbooks_invoice
    raise Ticketplease::ClientInvoiceAlreadyCreatedError.new if self.has_invoice?
    
    # Capture appropriate data from ledger and activities
    invoice_lines = []
    self.ledger_entries.debits.select( 'narrative, value, count(*) as quantity' ).group(:narrative, :value).each do |entry|
      invoice_lines << { line: { 
        name: '%s at %0.4f' % [entry.narrative, -entry.value],
        # description: entry.narrative,
        unit_cost: -entry.value,
        quantity: entry.quantity
      }}
    end
  
    # Create a new invoice data structure
    invoice_data = { return_uri: 'http://app.ticketpleaseapp.com', lines: invoice_lines }
    invoice_data[:po_number] = self.purchase_order unless self.purchase_order.blank?
    invoice_data[:notes] = 'This invoice is provided for information purposes only. No payment is due.' if self.balance >= 0
    
    # Update this invoice with all needed data
    response = Freshbooks.account.invoice.create(invoice_data)
    self.freshbooks_id = response['invoice_id']
    
    # Requery invoice - why? because Freshbooks doesn't send back all the data we expect!
    response = Freshbooks.account.invoice.get(self.freshbooks_id) unless response['invoice'].include?('links')
    self.public_link = response['invoice']['links']['client_view']
    self.internal_link = resonse['invoice']['links']['view']
  end
  
  ##
  # Create a new invoice in the financial system, saving afterwards.
  def create_freshbooks_invoice!
    self.create_freshbooks_invoice
    self.save!
  end
  
  alias :create_invoice :create_freshbooks_invoice
  alias :create_invoice! :create_freshbooks_invoice!
  alias :send_invoice! :send_freshbooks_invoice!
  
end