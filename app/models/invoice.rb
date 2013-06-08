class Invoice < ActiveRecord::Base
  include Workflow
  attr_accessible :date_from, :date_to, :sent_at
  
  belongs_to :organization, inverse_of: :invoices
  has_many :ledger_entries, inverse_of: :invoice, autosave: true
  
  validates_presence_of :organization, :date_to
  
  before_create :ensure_dates
  
  workflow do
    state :new do
      event :prepare, transitions_to: :prepared
    end
    state :prepared do
      event :settle, transitions_to: :settled
    end
    state :settled
  end

  def ensure_dates
    self.date_from ||= self.ledger_entries.minimum( 'created_at' )
    self.date_to   ||= self.ledger_entries.maximum( 'created_at' )
  end
  
  def default_date_to
    DateTime.yesterday.end_of_day
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
  # Ask FreshBooks for the current balance of the invoice
  def invoice_amount
    BigDecimal.new(self.freshbooks_invoice['amount']) rescue nil
  end

  ##
  # Ask FreshBooks for the current balance of the invoice
  def invoice_balance
    BigDecimal.new(self.freshbooks_invoice['amount_outstanding']) rescue nil
  end

  ##
  # Capture all uninvoiced, settled transactions and assign to this invoice.
  def capture_uninvoiced_ledger_entries!
    raise SignalCloud::SignalCloudError.new( 'Invoice must be saved before capturing ledger entries.' ) if self.new_record?
    self.date_to ||= self.default_date_to
    self.organization.ledger_entries.uninvoiced.debits.settled_before( self.date_to ).update_all( invoice_id: self.id )
    self.ledger_entries(true) # Force a reload of ledger_entries
  end
  
  ##
  # Send this invoice from the FreshBooks organizationing system.
  def send_freshbooks_invoice!
    raise SignalCloud::ClientInvoiceNotCreatedError.new unless self.has_invoice?
    
    response = FreshBooks.account.invoice.sendByEmail( invoice_id: self.freshbooks_invoice_id )
    raise SignalCloud::FreshBooksError.new( 'Could not send invoice: %s (%i)' % [ response['error'], response['code'] ], response['code'] ) unless response.success?

    self.freshbooks_invoice_id = response['invoice_id']
    self.sent_at = DateTime.now
    self.save!
  end
  
  ##
  # Create a new invoice in the financial system without saving.
  # Internally, we keep charges as negative (-); FreshBooks expects them to be positive (+), so we must invert the sign when passing to FB.
  def create_freshbooks_invoice!
    raise SignalCloud::OrganizationNotAssociatedError.new if self.organization.nil?
    raise SignalCloud::MissingFreshBooksClientError.new(self.organization) if self.organization.accounting_gateway.freshbooks_id.nil?
    raise SignalCloud::ClientInvoiceAlreadyCreatedError.new if self.has_invoice?

    # Update this invoice with the FB invoice id
    response = FreshBooks.account.invoice.create({ invoice: self.construct_freshbooks_invoice_data() })
    raise SignalCloud::FreshBooksError.new( 'Could not create invoice: %s (%i)' % [ response['error'], response['code'] ], response['code'] ) unless response.success?
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
    self.ledger_entries.debits.select( 'narrative, value, count(*) as quantity' ).group(:narrative, :value).each do |entry|
      invoice_lines << { line: { 
        name: entry.narrative,
        description: '%s at %0.4f' % [entry.narrative, -entry.value.to_f],
        unit_cost: -entry.value,
        quantity: entry.quantity
      }}
    end
  
    # Create a new invoice data structure
    invoice_data = { client_id: self.organization.accounting_gateway.freshbooks_id, return_uri: 'http://www.signalcloudapp.com' }
    invoice_data[:lines] = invoice_lines unless invoice_lines.empty?
    invoice_data[:po_number] = self.purchase_order unless self.purchase_order.blank?
    invoice_data[:notes] = 'This invoice is provided for information purposes only. No payment is due.' if self.balance >= 0
    
    return invoice_data
  end

  ##
  # Apply a single credit to this invoice.
  def apply_freshbooks_credit!
    credit = [ self.organization.accounting_gateway.available_credits[:USD], self.invoice_balance ].min
    response = FreshBooks.account.payment.create({ payment: {
      invoice_id: self.freshbooks_invoice_id,
      client_id: self.organization.accounting_gateway.freshbooks_id,
      amount: credit,
      type: 'Credit'
    }})
  end
  
  ##
  # Update self from FreshBooks data.
  def refresh_from_freshbooks
    fb_invoice = self.freshbooks_invoice
    self.public_link = fb_invoice['links']['client_view']
    self.internal_link = fb_invoice['links']['view']
  end
  
  def freshbooks_invoice
    raise SignalCloud::OrganizationNotAssociatedError.new if self.organization.nil?
    raise SignalCloud::MissingFreshBooksClientError.new(self.organization) if self.organization.accounting_gateway.freshbooks_id.nil?
    raise SignalCloud::ClientInvoiceNotCreatedError.new unless self.has_invoice?

    response = FreshBooks.account.invoice.get({ invoice_id: self.freshbooks_invoice_id })
    raise SignalCloud::FreshBooksError.new( 'Could not find invoice %i for client %i: %s (%i)' % [ self.freshbooks_invoice_id, self.organization.accounting_gateway.freshbooks_id, response['error'], response['code'] ], response['code'] ) unless response.success?
    return response['invoice']
  end

  #alias :create_invoice :create_freshbooks_invoice
  alias :create_invoice! :create_freshbooks_invoice!
  alias :send_invoice! :send_freshbooks_invoice!

protected

  ##
  # Prepare the contents of the invoice and save as a draft.
  def prepare
    self.capture_uninvoiced_ledger_entries!
    self.create_freshbooks_invoice!
    self.apply_freshbooks_credit!
  end

  ##
  # Automaticaly create, save, and send the freshbook invoice.
  def settle
    self.send_freshbooks_invoice!
  end

end