class Account < ActiveRecord::Base

  require 'account_xt_twilio'
  require 'account_xt_freshbooks'

  # General attributes
  attr_accessible :account_sid, :account_plan, :auth_token, :balance, :label, :account_plan_id, :description, :vat_name, :vat_number
  
  attr_accessor :balance_changed
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :freshbooks_id, key: ATTR_ENCRYPTED_SECRET

  # References
  belongs_to :account_plan, inverse_of: :accounts
  has_many :users, inverse_of: :account
  has_many :stencils, inverse_of: :account
  has_many :tickets, through: :stencils
  has_many :phone_directories, inverse_of: :account
  has_many :phone_directory_entries, through: :phone_directories
  has_many :phone_numbers, inverse_of: :account
  has_many :ledger_entries, inverse_of: :account
  has_many :invoices, inverse_of: :account
  has_one :primary_address, class_name: 'Address', autosave: true, dependent: :destroy
  has_one :secondary_address, class_name: 'Address', autosave: true, dependent: :destroy
  
  # Helper reference for all messages
  has_many :tickets, through: :stencils
  has_many :messages, through: :tickets
  
  # Nested resources
  accepts_nested_attributes_for :primary_address
  accepts_nested_attributes_for :secondary_address
  
  # Validations
  before_validation :ensure_account_sid_and_token
  validates_presence_of :account_sid, :auth_token, :label
  validates_uniqueness_of :account_sid
  after_create :create_initial_resources
  
  def ensure_account_sid_and_token
    self.account_sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  ##
  # Create starting 'default' directory and stencil for a newly created account
  def create_initial_resources
    initial_directory = self.phone_directories.create label: 'Default Directory'
    initial_stencil = self.stencils.create label: 'Default Stencil', phone_directory_id: initial_directory.id
  end

  ##
  # Return the default stencil for this account, or the first stencil if no default is set.
  def primary_stencil
    app = self.stencils.where( primary: true ).order('id').first
    app = self.stencils.first if app.nil?
    app
  end
  
  ##
  # Get statistics and counts for all tickets in this account. With return a hash of nicely labeled counts.
  def ticket_count_by_status()
    statuses = Ticket.count_by_status_hash( self.tickets.today )
  end
  
  def last_invoice_date()
#     invoice_date = self.invoices.maximum('date_to')
#     return invoice_date unless invoice_date.nil?
#     
#     ledger_date = self.ledger_entries.minimum('created_at')
#     return ledger_date unless ledger_date.nil? 
    
    date = ( self.invoices.maximum('date_to') || self.ledger_entries.minimum('created_at') )
    raise 'cannot create invoice - no ledger entries' if date.nil?
    return date.to_time
  end
  
  def update_balance!( delta )
    self.class.update_all( ['balance = balance + ?', delta ], id: self.id )
    self.balance_changed = true
  end
  
  def balance()
    self.reload if self.balance_changed
    super
  end

end
