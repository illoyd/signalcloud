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

  # References
  has_many :user_roles, inverse_of: :organization
  has_many :users, through: :user_roles
  belongs_to :owner, class_name: 'User', inverse_of: :owned_organizations

  has_one :account_balance, inverse_of: :organization, autosave: true, dependent: :destroy
  
  has_many :communication_gateways, inverse_of: :organization, autosave: true

  has_one :accounting_gateway, inverse_of: :organization
  has_one :payment_gateway, inverse_of: :organization

  belongs_to :account_plan, inverse_of: :organizations
  has_many :boxes, inverse_of: :organization
  has_many :stencils, inverse_of: :organization
  has_many :conversations, through: :stencils
  has_many :phone_books, inverse_of: :organization
  has_many :phone_book_entries, through: :phone_books
  has_many :phone_numbers, inverse_of: :organization
  has_many :ledger_entries, inverse_of: :organization
  has_many :invoices, inverse_of: :organization

  # Helper reference for all messages
  has_many :conversations, through: :stencils
  has_many :messages, through: :conversations
  
  # Validations
  validates_presence_of :sid, :auth_token, :label, :account_balance, :account_plan
  validates_presence_of :billing_first_name, :billing_last_name, :billing_work_phone, if: Proc.new { |org| org.billing_country.present? }
  validates_presence_of :contact_first_name, :contact_last_name, :contact_work_phone, if: Proc.new { |org| org.contact_country.present? }
  validates_uniqueness_of :sid
  
  # Callbacks
  before_validation :ensure_sid_and_token
  before_validation :ensure_account_balance
  before_validation :apply_use_same_address
  before_create :ensure_initial_resources
  
  # Delegations
  delegate :update_balance!, :balance, :balance=, to: :account_balance
  delegate :freshbooks_id, to: :accounting_gateway

  def icon
    super || :briefcase
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
  
  ##
  # Return the date of the last invoice, or the first ledger_entry
  def last_invoice_date
    self.invoices.maximum('date_to') #.to_time rescue nil
  end
  
  ##
  # Get the communication gateway for a particular service
  def communication_gateway_for( service )
    klass = case service.to_sym
      when :twilio
        TwilioCommunicationGateway.name
      when :mock
        MockCommunicationGateway.name
      when :nexmo
        raise RuntimeError.new('Nexmo service not yet configured!')
      else
        raise RuntimeError.new('Unrecognised service %s!' % [service.to_s])
      end
    self.communication_gateways.where( type: klass ).first
  end
  
  def communication_gateway_for?( service )
    !communication_gateway_for( service ).nil?
  end

  ##
  # Billing address value object getter.
  def billing_address
    Address.new(
      self.billing_first_name,
      self.billing_last_name,
      self.billing_email,
      self.billing_work_phone,
      self.billing_line1,
      self.billing_line2,
      self.billing_city,
      self.billing_region,
      self.billing_postcode,
      self.billing_country
    )
  end
  
  ##
  # Billing address value assigner.
  def billing_address= address
    address = Address.new if address.nil?
    self.billing_first_name = address.first_name
    self.billing_last_name  = address.last_name
    self.billing_email      = address.email
    self.billing_work_phone = address.work_phone
    self.billing_line1      = address.line1
    self.billing_line2      = address.line2
    self.billing_city       = address.city
    self.billing_region     = address.region
    self.billing_postcode   = address.postcode
    self.billing_country    = address.country
    address   
  end
  
  ##
  # Contact address value object getter.
  def contact_address
    Address.new(
      self.contact_first_name,
      self.contact_last_name,
      self.contact_email,
      self.contact_work_phone,
      self.contact_line1,
      self.contact_line2,
      self.contact_city,
      self.contact_region,
      self.contact_postcode,
      self.contact_country
    )
  end
  
  ##
  # Contact address value assigner.
  def contact_address= address
    address = Address.new if address.nil?
    self.contact_first_name = address.first_name
    self.contact_last_name  = address.last_name
    self.contact_email      = address.email
    self.contact_work_phone = address.work_phone
    self.contact_line1      = address.line1
    self.contact_line2      = address.line2
    self.contact_city       = address.city
    self.contact_region     = address.region
    self.contact_postcode   = address.postcode
    self.contact_country    = address.country
    address
  end
  
protected

  ##
  # Add SID and Auth Token (for API access) on first create.
  def ensure_sid_and_token
    self.sid        ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
    true
  end
  
  ##
  # Build a new account balance if not already defined.
  def ensure_account_balance
    self.build_account_balance if self.account_balance.nil?
    true
  end
  
  ##
  # Create starting 'default' book and stencil for a newly created organization
  def ensure_initial_resources
    initial_book = self.phone_books.build( organization: self, label: 'Default Book' ) if self.phone_books.empty?
    initial_stencil = self.stencils.build( organization: self, label: 'Default Stencil', phone_book: self.phone_books.first ) if self.stencils.empty?
    true
  end

  ##
  # Automatically use the billing address as the contact address if requested.
  def apply_use_same_address
    self.contact_address = self.billing_address if self.use_billing_as_contact_address?
    true
  end

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
