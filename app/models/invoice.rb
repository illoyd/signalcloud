class Invoice < ActiveRecord::Base
  attr_accessible :freshbooks_invoice_id, :date_from, :date_to, :sent_at
  
  belongs_to :organization, inverse_of: :invoices
  has_many :ledger_entries, inverse_of: :invoice
  
  validates_presence_of :organization_id, :date_to
  
  before_create :ensure_dates
  
  def ensure_dates
    self.date_from ||= self.ledger_entries.minimum( 'created_at' )
  end
  
  ##
  # Does this invoice have an associated invoice in the finance system?
  def has_invoice?
    !self.freshbooks_invoice_id.nil?
  end

  ##
  # Calculate the sum of all ledger entries for this invoice's period.
  # At the moment, this is not cached, so use it sparingly.
  def balance
    self.ledger_entries.sum(:value)
  end
  
  ##
  # Capture all uninvoiced, settled transactions and assign to this invoice.
  def capture_uninvoiced_ledger_entries
    raise SignalCloudError.new( 'Invoice must be saved before capturing ledger entries.' ) if self.new_record?
    self.organization.ledger_entries.uninvoiced.settled.where( 'settled_at <= ?', self.date_to ).update_all( invoice_id: self.id )
    self.ledger_entries(true) # Force a reload of ledger_entries
  end
  
  ##
  # Automaticaly create, save, and send the freshbook invoice.
  def settle
    self.capture_uninvoiced_ledger_entries
    self.create_freshbooks_invoice
    self.send_freshbooks_invoice!
  end
  
  ##
  # Send this invoice from the FreshBooks organizationing system.
  def send_freshbooks_invoice!
    raise SignalCloud::ClientInvoiceNotCreatedError.new unless self.has_invoice?
    
    response = Freshbooks.organization.invoice.send_by_email( invoice_id: self.freshbooks_invoice_id )
    self.freshbooks_invoice_id = response['invoice_id']
    self.sent_at = DateTime.now
    self.save!
  end
  
  ##
  # Apply all credits for this period to the organization.
  def apply_freshbooks_credits()
    self.ledger_entries.credits.settled.uninvoiced.each do |entry|
      self.apply_freshbooks_credit( entry )
    end
  end
  
  ##
  # Apply a single credit to this invoice.
  def apply_freshbooks_credit( ledger_entry )
    response = Freshbooks.organization.payment.create({
      invoice_id: self.freshbooks_invoice_id,
      client_id: self.organization.freshbooks_id,
      amount: ledger_entry.value,
      date: ledger_entry.created_at,
      type: 'Credit',
      notes: ledger_entry.narrative
    })
    
    ledger_entry.invoiced_at = DateTime.now
    ledger_entry.save!
  end
  
  ##
  # Update self from FreshBooks data.
  def refresh_from_freshbooks
    raise SignalCloud::OrganizationNotAssociatedError.new if self.organization.nil?
    raise SignalCloud::FreshBooksAccountNotConfiguredError.new if self.organization.freshbooks_id.nil?
    raise SignalCloud::MissingClientInvoiceError.new unless self.has_invoice?

    response = Freshbooks.organization.invoice.get({ invoice_id: self.freshbooks_invoice_id })
    self.public_link = response['invoice']['links']['client_view']
    self.internal_link = response['invoice']['links']['view']
  end
  
  ##
  # Create a new invoice in the financial system without saving.
  # Internally, we keep charges as negative (-); FreshBooks expects them to be positive (+), so we must invert the sign when passing to FB.
  def create_freshbooks_invoice!
    raise SignalCloud::OrganizationNotAssociatedError.new if self.organization.nil?
    raise SignalCloud::FreshBooksAccountNotConfiguredError.new if self.organization.freshbooks_id.nil?
    raise SignalCloud::ClientInvoiceAlreadyCreatedError.new if self.has_invoice?

    # Update this invoice with the FB invoice id
    response = Freshbooks.organization.invoice.create({ invoice: self.construct_freshbooks_invoice_data() })
    raise FreshBooksError.new ( 'Create invoice failed' ) unless response.include?('invoice_id')
    self.freshbooks_invoice_id = response['invoice_id']
    
    # Refresh from FB, since they do not provide all the information we require
    self.refresh_from_freshbooks()
    
    # Finally, save all updates
    self.save!
  end
  
  ## 
  # Helper to build the invoice data structures.
  def construct_freshbooks_invoice_data
    # Capture appropriate data from ledger and activities
    invoice_lines = []
    self.ledger_entries.debits.settled.uninvoiced.select( 'narrative, value, count(*) as quantity' ).group(:narrative, :value).each do |entry|
      invoice_lines << { line: { 
        name: '%s at %0.4f' % [entry.narrative, -entry.value],
        # description: entry.narrative,
        unit_cost: -entry.value,
        quantity: entry.quantity
      }}
    end
  
    # Create a new invoice data structure
    invoice_data = { client_id: self.organization.freshbooks_id, return_uri: 'http://app.signalcloudapp.com' }
    invoice_data[:lines] = invoice_lines unless invoice_lines.empty?
    invoice_data[:po_number] = self.purchase_order unless self.purchase_order.blank?
    invoice_data[:notes] = 'This invoice is provided for information purposes only. No payment is due.' if self.balance >= 0
    
    return invoice_data
  end
  
  #alias :create_invoice :create_freshbooks_invoice
  alias :create_invoice! :create_freshbooks_invoice!
  alias :send_invoice! :send_freshbooks_invoice!
  
end