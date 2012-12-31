class Account < ActiveRecord::Base
  # General attributes
  attr_accessible :account_sid, :account_plan, :auth_token, :balance, :label, :account_plan_id, :description
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET

  # References
  belongs_to :account_plan, inverse_of: :accounts
  has_many :users, inverse_of: :account
  has_many :appliances, inverse_of: :account
  has_many :tickets, through: :appliances
  has_many :phone_directories, inverse_of: :account
  has_many :phone_numbers, inverse_of: :account
  has_many :transactions, inverse_of: :account
  
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
  
  def create_initial_resources

    # Create first directory
    default_directory = self.phone_directories.build label: 'Default Directory'
  
    # Build first appliance
    default_appliance = default_directory.appliances.build label: 'Default Appliance'
    default_appliance.account = self
    
  end
  
  def default_appliance
    self.appliances.find_by_default( true )
  end
  
  def ticket_statistics
    return {
      expired: self.tickets.where( status: Ticket::EXPIRED ).count,
      denied: self.tickets.where( status: Ticket::DENIED ).count,
      failed: self.tickets.where( status: Ticket::FAILED ).count,
      confirmed: self.tickets.where( status: Ticket::CONFIRMED ).count,
      queued: self.tickets.where( status: Ticket::QUEUED ).count,
      sent: self.tickets.where( status: Ticket::CHALLENGE_SENT ).count
    }
  end
  
  def additive_ticket_statistics
    statistics = self.ticket_statistics
    return {
      expired: statistics[:expired],
      denied: statistics[:expired] + statistics[:denied],
      failed: statistics[:expired] + statistics[:denied] + statistics[:failed],
      confirmed: statistics[:expired] + statistics[:denied] + statistics[:failed] + statistics[:confirmed]
    }
  end
  
end
