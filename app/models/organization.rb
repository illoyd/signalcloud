class Organization < ActiveRecord::Base

  READY = 2
  PENDING = 1
  TRIAL = 0
  
  require 'organization_xt_twilio'
  require 'organization_xt_freshbooks'

  # General attributes
  attr_accessible :sid, :account_plan, :auth_token, :label, :account_plan_id, :description, :vat_name, :vat_number, :icon, :contact_address_attributes, :billing_address_attributes
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :freshbooks_id, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :braintree_id, key: ATTR_ENCRYPTED_SECRET

  # References
  has_many :user_roles, inverse_of: :organization
  has_many :users, through: :user_roles

  has_one :account_balance, inverse_of: :organization, autosave: true, dependent: :destroy
  
  belongs_to :account_plan, inverse_of: :organizations
  has_many :stencils, inverse_of: :organization
  has_many :conversations, through: :stencils
  has_many :phone_books, inverse_of: :organization
  has_many :phone_book_entries, through: :phone_books
  has_many :phone_numbers, inverse_of: :organization
  has_many :ledger_entries, inverse_of: :organization
  has_many :invoices, inverse_of: :organization
  has_one :contact_address, class_name: 'Address', autosave: true, dependent: :destroy
  has_one :billing_address, class_name: 'Address', autosave: true, dependent: :destroy
  
  # Helper reference for all messages
  has_many :conversations, through: :stencils
  has_many :messages, through: :conversations
  
  # Nested resources
  accepts_nested_attributes_for :contact_address
  accepts_nested_attributes_for :billing_address
  
  # Validations
  validates_presence_of :sid, :auth_token, :label, :account_balance
  validates_uniqueness_of :sid
  
  # Callbacks
  before_validation :ensure_sid_and_token
  before_validation :ensure_account_balance
  after_create :create_initial_resources
  
  def ensure_sid_and_token
    self.sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  def ensure_account_balance
    self.build_account_balance if self.account_balance.nil?
  end

  def status
    tests = [ self.twilio_account_sid, self.braintree_id, self.freshbooks_id ]
    return case
      when tests.all? { |x| x }
        READY
      when tests.any? { |x| x }
        PENDING
      else
        TRIAL
    end
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
  
  delegate :update_balance!, :balance, :balance=, to: :account_balance
  
end
