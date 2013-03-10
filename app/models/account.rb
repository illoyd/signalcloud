class Account < ActiveRecord::Base
  # General attributes
  attr_accessible :account_sid, :account_plan, :auth_token, :balance, :label, :account_plan_id, :description, :vat_name, :vat_number
  
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
  has_many :ledger_entries, inverse_of: :account
  has_many :invoices, inverse_of: :account
  has_one :primary_address, class_name: 'Address', autosave: true, dependent: :destroy
  has_one :secondary_address, class_name: 'Address', autosave: true, dependent: :destroy
  
  # Helper reference for all messages
  has_many :tickets, through: :appliances
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
  # Send an SMS using the Twilio API.
  def send_sms( to_number, from_number, body )
    return self.twilio_account.sms.messages.create(
      to: to_number,
      from: from_number,
      body: body
    )
  end
  
  ##
  # Return a Twilio Client.
  def twilio_client
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    @twilio_client ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
    return @twilio_client
  end
  
  ##
  # Return a Twilio Account.
  def twilio_account
    return self.twilio_client.account
  end
  
  ##
  # Return a Twilio Validator.
  def twilio_validator
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
    return @twilio_validator
  end
  
  def create_twilio_account
    begin
      return self.create_twilio_account!
    rescue Ticketplease::TwilioAccountAlreadyExistsError
      return nil
    end
  end
  
  ##
  # Create a Twilio sub-account.
  def create_twilio_account!
    raise Ticketplease::TwilioAccountAlreadyExistsError.new(self) unless self.twilio_account_sid.blank? and self.twilio_auth_token.blank?
    response = Twilio.master_client.accounts.create( 'FriendlyName' => self.label )
    self.twilio_account_sid = response.sid
    self.twilio_auth_token = response.auth_token
    # self.save!
    return response
  end
  
  ##
  # Create, or update if it exists, the Twilio application used for this account.
  def create_or_update_twilio_application
    return self.twilio_application_sid.blank? ? self.create_twilio_application : self.update_twilio_application
  end
  
  def create_twilio_application
    begin
      return self.create_twilio_application!
    rescue Ticketplease::TwilioApplicationAlreadyExistsError
      return nil
    end
  end
  
  def create_twilio_application!
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    raise Ticketplease::TwilioApplicationAlreadyExistsError.new(self) unless self.twilio_application_sid.blank?

    response = self.twilio_account.applications.create(self.twilio_application_configuration)
    self.twilio_application_sid = response.sid
    return response
  end
  
  def update_twilio_application
    begin
      return self.update_twilio_application!
    rescue Ticketplease::MissingTwilioApplicationError
      return nil
    end
  end
  
  def update_twilio_application!
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    raise Ticketplease::MissingTwilioApplicationError.new(self) if self.twilio_application_sid.blank?

    return self.twilio_account.applications.get(self.twilio_application_sid).update(self.twilio_application_configuration)
  end
  
  def has_twilio_application?
    return !self.twilio_application_sid.blank?
  end
  
  def twilio_application_configuration( options={} )
    return {
      'FriendlyName' => '%s\'s Application' % self.label,

      'VoiceUrl' => self.twilio_voice_url,
      'VoiceMethod' => 'POST',

      'VoiceFallbackUrl' => self.twilio_voice_url,
      'VoiceFallbackMethod' => 'POST',

      'StatusCallback' => self.twilio_voice_status_url,
      'StatusCallbackMethod' => 'POST',

      'SmsUrl' => self.twilio_sms_url,
      'SmsMethod' => 'POST',
      
      'SmsFallbackUrl' => self.twilio_sms_url,
      'SmsFallbackMethod' => 'POST',

      'SmsStatusCallback' => self.twilio_sms_status_url
    }.merge(options)

  end
  
  def twilio_voice_url
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_call_url
  end
  
  def twilio_voice_status_url
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_call_update_url
  end
  
  def twilio_sms_url
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_sms_url
  end
  
  def twilio_sms_status_url
    raise Ticketplease::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_sms_update_url
  end
  
  def insert_twilio_authentication( url )
  
    # Insert digest authentication
    unless self.twilio_account_sid.blank?
      auth_string = self.account_sid
      auth_string += ':' + self.auth_token unless self.auth_token.blank?
      url = url.gsub( /(https?:\/\/)/, '\1' + auth_string + '@' )
    end
    
    # Force it to secure HTTPS
    return url.gsub( /\Ahttp:\/\//, 'https://' )
  end
  
  ##
  # Get the current client's FreshBook account, using the FreshBook global module.
  # In FreshBooks parlance, this is a 'Client' object.
  def freshbooks_client
    raise Ticketplease::MissingFreshBooksClientError.new(self) if self.freshbooks_id.blank?
    Freshbooks.account.client.get client_id: self.freshbooks_id
  end
  
  ##
  # Create a new FreshBooks client for this account. This method will throw an error if a FreshBooks client already exists.
  def create_freshbooks_client
    raise Ticketplease::FreshBooksClientAlreadyExistsError.new(self) unless self.freshbooks_id.nil?
    raise Ticketplease::FreshBooksError.new( 'Missing a primary contact.' ) if self.primary_address.nil?
    
    # Construct the complete client dataset to be passed to Freshbooks
    contact = self.users.first
    client_data = {
      organisation: self.label,
      currency_code: Freshbooks::DEFAULT_CURRENCY
    }
    
    # Insert primary address if appropriate
    unless self.primary_address.nil?
      client_data.merge!({
        # Add primary contact
        first_name: self.primary_address.first_name,
        last_name:  self.primary_address.last_name,
        username:   self.primary_address.email,
        email:      self.primary_address.email,
        work_phone: self.primary_address.work_phone,
        # Add address
        p_street1:  self.primary_address.line1,
        p_street2:  self.primary_address.line2,
        p_city:     self.primary_address.city,
        p_state:    self.primary_address.region,
        p_country:  self.primary_address.country,
        p_code:     self.primary_address.postcode
      })
    end
    
    # Insert secondary address if appropriate
    unless self.secondary_address.nil?
      client_data.merge!({
        s_street1:  self.secondary_address.line1,
        s_street2:  self.secondary_address.line2,
        s_city:     self.secondary_address.city,
        s_state:    self.secondary_address.region,
        s_country:  self.secondary_address.country,
        s_code:     self.secondary_address.postcode
      })
    end
    
    # Insert VAT data if appropriate
    client_data[:vat_name] unless self.vat_name.blank?
    client_data[:vat_number] unless self.vat_number.blank?
    
    # Instruct FreshBooks API to create the account, then save the resulting ID
    response = Freshbooks.account.client.create(client_data)
    self.freshbooks_id = response['client_id']
    self.save!
  end
  
  ##
  # Generate a new FreshBooks invoice.
  def create_freshbook_invoice( to_date=nil, from_date=nil )
    from_date ||= (self.invoices.last.to_date + 1.day).beginning_of_day
    to_date ||= DateTime.yesterday.end_of_day
    invoice = self.invoices.build from_date: from_date, to_date: to_date
    invoice.create_invoice!
  end
  
  ##
  # Create starting 'default' directory and appliance for a newly created account
  def create_initial_resources
    initial_directory = self.phone_directories.create label: 'Default Directory'
    initial_appliance = self.appliances.create label: 'Default Appliance', phone_directory_id: initial_directory.id
  end

  ##
  # Return the default appliance for this account, or the first appliance if no default is set.
  def primary_appliance
    app = self.appliances.where( primary: true ).order('id').first
    app = self.appliances.first if app.nil?
    app
  end
  
  ##
  # Get statistics and counts for all tickets in this account. With return a hash of nicely labeled counts.
  def ticket_count_by_status()
    statuses = Ticket.count_by_status_hash( self.tickets.today )
  end
  
end
