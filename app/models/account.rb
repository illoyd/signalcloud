class Account < ActiveRecord::Base
  # General attributes
  attr_accessible :account_sid, :account_plan, :auth_token, :balance, :label, :account_plan_id, :description
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :freshbooks_id, key: ATTR_ENCRYPTED_SECRET

  # References
  belongs_to :account_plan, inverse_of: :accounts
  has_many :users, inverse_of: :account
  has_many :appliances, inverse_of: :account
  has_many :tickets, through: :appliances
  has_many :phone_directories, inverse_of: :account
  has_many :phone_numbers, inverse_of: :account
  has_many :transactions, inverse_of: :account
  has_many :invoices, inverse_of: :account
  has_one :primary_address, class_name: 'Address', autosave: true, dependent: :destroy
  hsa_one :secondary_address, class_name: 'Address', autosave: true, dependent: :destroy
  
  # Nested resources
  accepts_nested_attributes_for :primary_address
  accepts_nested_attributes_for :secondary_address
  
  # Validations
  before_validation :ensure_account_sid_and_token
  validates_presence_of :account_sid, :auth_token, :label
  validates_uniqueness_of :account_sid
  before_create :create_initial_resources
    
  def ensure_account_sid_and_token
    self.account_sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  ##
  # Send an SMS using the Twilio API.
  def send_sms( to_number, from_number, body )
    return self.twilio_account.sms.messages.create(
      to: to_number,
      from: from_number,
      body: body
    )
  end
  
  def twilio_client
    # TODO: Add error if twilio account details are not defined
    @twilio_client ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
    return @twilio_client
  end
  
  def twilio_account
    # TODO: Add error if twilio account details are not defined
    return self.twilio_client.account
  end
  
  def twilio_validator
    # TODO: Add error if twilio account details are not defined
    @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
    return @twilio_validator
  end
  
  ##
  # Get the current client's Freshbook account, using the Freshbook global module.
  # In Freshbooks parlance, this is a 'Client' object.
  def freshbooks_client
    Freshbooks.account.client.get client_id: self.freshbooks_id
  end
  
  def create_freshbooks_client
    raise 'Freshbooks client already configured' unless self.freshbooks_id.nil?
    
    # Construct the complete client dataset to be passed to Freshbooks
    contact = self.users.primary
    client_data = {
      organisation: self.organisation,
      currency_code: 'USD',
      # VAT details
      vat_name: self.vat_name,
      vat_number: self.vat_number,
      # Add primary contact
      first_name: contact.first_name,
      last_name: contact.last_name,
      username: contact.email,
      email: contact.email,
      work_phone: self.primary_address.work_phone,
      # Add primary address
      p_street1: self.primary_address.line1,
      p_street2: self.primary_address.line2,
      p_city: self.primary_address.city,
      p_state: self.primary_address.state,
      p_country: self.primary_address.country,
      p_code: self.primary_address.postalcode,
      # Add secondary address
      s_street1: self.secondary_address.line1,
      s_street2: self.secondary_address.line2,
      s_city: self.secondary_address.city,
      s_state: self.secondary_address.state,
      s_country: self.secondary_address.country,
      s_code: self.secondary_address.postalcode,
      # Manage all contacts
      contacts: []
    }
    
    # Instruct Freshbooks API to create the account, then save the resulting ID
    response = Freshbooks.account.client.create(client_data)
    self.freshbooks_id = response[:client_id]
    self.save!
  end
  
  def create_freshbook_invoice( to_date=nil, from_date=nil )
    from_date ||= (self.invoices.last.to_date + 1.day).beginning_of_day
    to_date ||= DateTime.yesterday.end_of_day
    invoice = self.invoices.build from_date: from_date, to_date: to_date
    invoice.create_invoice!
  end
  
  ##
  # Create starting 'default' directory and appliance for a newly created account
  def create_initial_resources
    default_directory = self.phone_directories.build label: 'Default Directory'
    default_appliance = self.appliances.build label: 'Default Appliance', default_directory_id: default_directory.id
  end

  def default_appliance
    self.appliances.find_by_default( true )
  end
  
  def ticket_statistics
    total = self.tickets.today.count
    return {
      expired: self.tickets.today.where( status: Ticket::EXPIRED ).count.to_f / total * 100.0,
      denied: self.tickets.today.where( status: Ticket::DENIED ).count.to_f / total * 100.0,
      failed: self.tickets.today.where( status: Ticket::FAILED ).count.to_f / total * 100.0,
      confirmed: self.tickets.today.where( status: Ticket::CONFIRMED ).count.to_f / total * 100.0,
      queued: self.tickets.today.where( status: Ticket::QUEUED ).count.to_f / total * 100.0,
      sent: self.tickets.today.where( status: Ticket::CHALLENGE_SENT ).count.to_f / total * 100.0
    }
  end
  
  def additive_ticket_statistics
    statistics = self.ticket_statistics
    total = statistics.values.sum
    additive_statistics = {}
    [ :queued, :sent, :confirmed, :expired, :failed, :denied ].each { |key| additive_statistics[key] = additive_statistics.values.sum + statistics[key] }
    additive_statistics.each { |key,value| additive_statistics[key] = value }
    return additive_statistics
  end
  
end
