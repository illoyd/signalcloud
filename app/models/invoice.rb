class Message < ActiveRecord::Base
  attr_accessible :freshbooks_id, :date_from, :date_to
  
  belongs_to :account, inverse_of :invoices
  
  alias :create_invoice :create_freshbooks_invoice
  alias :create_invoice! :create_freshbooks_invoice!
  
  def has_invoice?
    !self.freshbooks_id.nil?
  end

  def ledger_entries
    self.account.ledger_entries.where( 'ledger_entries.created_at >= ? and ledger_entries.created_at <= ?', self.from_date, self.to_date )
  end
  
  def debit_ledger_entries
    self.ledger_entries.where( 'value <= 0' )
  end
  
  def credit_ledger_entries
    self.ledger_entries.where( 'value > 0' )
  end
  
  def create_and_send_freshbooks_invoice!
    self.create_freshbooks_invoice!
    self.send_freshbooks_invoice!
  end
  
  def send_freshbooks_invoice!
    raise 'Invoice not created' unless self.has_invoice?
    Freshbooks.account.invoice.send_by_email( invoice_id: self.freshbooks_id )
  end
  
  def apply_freshbooks_credits()
    self.credit_ledger_entries.select( 'narrative, sum(value) as value, created_at' ).group(:narrative).each do |entry|
      self.apply_freshbooks_credit( entry )
    end
  end
  
  def apply_freshbooks_credit( ledger_entry )
    response = Freshbooks.account.payment.create {
      invoice_id: self.freshbooks_id,
      client_id: self.account.freshbooks_id,
      amount: ledger_entry.value,
      date: ledger_entry.created_at,
      type: 'Credit',
      notes: ledger_entry.narrative
    }
  end
  
  def create_freshbooks_invoice
    raise 'Invoice already created' if self.has_invoice?
    
    # Capture appropriate data from ledger and activities
    invoice_lines = []
    self.debit_ledger_entries.select( 'narrative, sum(value) as value, count(*) as quantity' ).group(:narrative, :value).each do |entry|
      invoice_lines << { line: { 
        name: '%s at %0.4f' % [entry.narrative, -entry.value]
        # description: entry.narrative,
        unit_cost: -entry.value,
        quantity: entry.quantity
      }
    end
  
    # Create a new invoice data structure
    invoice_data = {
      return_uri: account_path( self.account ),
      lines: invoice_lines
    }
    invoice_data[:po_number] = self.purchase_order unless self.purchase_order.blank?
    invoice_data[:notes] = 'This invoice is provided for information purposes only. No payment is due.' unless self.account_plan.payable_in_arrears?
    
    # Update this invoice with all needed data
    response = Freshbooks.account.invoice.create(invoice_data)
    self.freshbooks_id = response[:invoice_id]
    response = Freshbooks.account.invoice.get(self.freshbooks_id)
    self.public_link = response[:links][:client_view]
    self.internal_link = resonse[:links][:view]
  end
  
  def create_freshbooks_invoice!
    self.create_freshbooks_invoice
    self.save!
  end
  
end