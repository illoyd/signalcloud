class Organization < ActiveRecord::Base

  require 'organization_xt_twilio'
  require 'organization_xt_freshbooks'

  # General attributes
  attr_accessible :sid, :account_plan, :auth_token, :balance, :label, :account_plan_id, :description, :vat_name, :vat_number, :icon
  
  attr_accessor :balance_changed
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :freshbooks_id, key: ATTR_ENCRYPTED_SECRET

  # References
  has_many :user_roles, inverse_of: :organization
  has_many :users, through: :user_roles
  
  belongs_to :account_plan, inverse_of: :organizations
  has_many :stencils, inverse_of: :organization
  has_many :conversations, through: :stencils
  has_many :phone_books, inverse_of: :organization
  has_many :phone_book_entries, through: :phone_books
  has_many :phone_numbers, inverse_of: :organization
  has_many :ledger_entries, inverse_of: :organization
  has_many :invoices, inverse_of: :organization
  has_one :primary_address, class_name: 'Address', autosave: true, dependent: :destroy
  has_one :secondary_address, class_name: 'Address', autosave: true, dependent: :destroy
  
  # Helper reference for all messages
  has_many :conversations, through: :stencils
  has_many :messages, through: :conversations
  
  # Nested resources
  accepts_nested_attributes_for :primary_address
  accepts_nested_attributes_for :secondary_address
  
  # Validations
  before_validation :ensure_sid_and_token
  validates_presence_of :sid, :auth_token, :label
  validates_uniqueness_of :sid
  after_create :create_initial_resources
  
  def ensure_sid_and_token
    self.sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  ##
  # Create starting 'default' book and stencil for a newly created organization
  def create_initial_resources
    initial_book = self.phone_books.create label: 'Default Book'
    initial_stencil = self.stencils.create label: 'Default Stencil', phone_book_id: initial_book.id
  end

  ##
  # Return the default stencil for this organization, or the first stencil if no default is set.
  def default_stencil
    app = self.stencils.where( primary: true ).order('id').first
    app = self.stencils.first if app.nil?
    app
  end
  
  ##
  # Get statistics and counts for all conversations in this organization. With return a hash of nicely labeled counts.
  def conversation_count_by_status()
    statuses = Conversation.count_by_status_hash( self.conversations.today )
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
