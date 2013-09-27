class Organization < ActiveRecord::Base
  include Workflow
  
  workflow do
    state :trial do
      event :upgrade, transition_to: :ready
    end
    state :ready do
      event :suspend, transition_to: :suspended
      event :cancel, transition_to: :cancelled
      event :upgrade, transition_to: :ready
    end
    state :suspended do
      event :upgrade, transition_to: :ready
      event :cancel, transition_to: :cancelled
    end
    state :cancelled
  end
  
  # Encrypted attributes
  # attr_encrypted :braintree_id, key: ATTR_ENCRYPTED_SECRET

  # References
  has_many :user_roles, inverse_of: :organization
  has_many :users, through: :user_roles
  belongs_to :owner, class_name: 'User', inverse_of: :owned_organizations

  has_one :account_balance, inverse_of: :organization, autosave: true, dependent: :destroy
  
  has_many :communication_gateways, inverse_of: :organization

  has_one :accounting_gateway, inverse_of: :organization
  has_one :payment_gateway, inverse_of: :organization

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
  validates_presence_of :sid, :auth_token, :label, :account_balance, :account_plan
  # validates_uniqueness_of :sid
  
  # Callbacks
  before_validation :ensure_sid_and_token
  before_validation :ensure_account_balance
  before_create :ensure_initial_resources
  
  # Delegations
  delegate :update_balance!, :balance, :balance=, to: :account_balance
  # delegate :has_twilio_application?, :twilio_client, :twilio_account, :twilio_account_sid, :twilio_validator, :send_sms!, to: :communication_gateway
  delegate :freshbooks_id, to: :accounting_gateway

  def ensure_sid_and_token
    self.sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  def ensure_account_balance
    self.build_account_balance if self.account_balance.nil?
  end
  
  def icon
    @icon || :briefcase
  end

  ##
  # Create starting 'default' book and stencil for a newly created organization
  def ensure_initial_resources
    initial_book = self.phone_books.build( organization: self, label: 'Default Book' ) if self.phone_books.empty?
    initial_stencil = self.stencils.build( organization: self, label: 'Default Stencil', phone_book: self.phone_books.first ) if self.stencils.empty?
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
  
  def has_accounting_gateway?
    !self.accounting_gateway.nil?
  end
  
#   def has_communication_gateway?
#     !self.communication_gateway.nil?
#   end
  
  def has_payment_gateway?
    !self.payment_gateway.nil?
  end

  ##
  # Return the date of the last invoice, or the first ledger_entry
  def last_invoice_date
    self.invoices.maximum('date_to') #.to_time rescue nil
  end

private

  def upgrade
    # Update SMS data if needed - this should be created when first needed
    # self.create_or_update_communication_gateway

    # Update accounting data if needed
    self.create_or_update_client
    
    # Update payment data if needed
    self.create_or_update_payment_gateway
  end
  
  def suspend
    # No need for additional work at this point
  end
  
  def cancel
    # Release all phone numbers
    self.phone_numbers.active.each do |phone_number|
      phone_number.unpurchase!
    end
    
    # Cancel the communication gateway
    self.communication_gateways.each do |gateway|
      gateway.cancel!
    end
  end

end
