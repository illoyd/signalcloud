class Account < ActiveRecord::Base
  # General attributes
  attr_accessible :account_sid, :account_plan, :auth_token, :balance, :label, :account_plan_id
  
  # Encrypted attributes
  attr_encrypted :twilio_account_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :twilio_auth_token, key: ATTR_ENCRYPTED_SECRET

  # References
  belongs_to :account_plan, inverse_of: :accounts
  has_many :users, inverse_of: :account
  has_many :appliances, inverse_of: :account
  has_many :phone_directories, inverse_of: :account
  
  before_validation :ensure_account_sid_and_token
  validates_presence_of :account_sid, :auth_token, :label
  validates_uniqueness_of :account_sid
    
  def ensure_account_sid_and_token
    self.account_sid ||= SecureRandom.hex(32)
    self.auth_token ||= SecureRandom.hex(32)
  end
  
  def twilio_account
    # TODO: Add error if twilio account details are not defined
    @twilio_account ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
    return @twilio_account
  end
  
  def twilio_validator
    # TODO: Add error if twilio account details are not defined
    @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
    return @twilio_validator
  end
  
end
