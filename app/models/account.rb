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
  
  ##
  # Create a Twilio sub-account.
  def create_twilio_account!
    raise Ticketplease::TwilioAccountAlreadyExistsError.new(self) unless self.twilio_account_sid.blank? and self.twilio_auth_token.blank?
    response = Twilio.master_client.accounts.create( 'FriendlyName' => self.label )
    self.twilio_account_sid = response.sid
    self.twilio_auth_token = response.auth_token
    self.save!
  end
  
  ##
  # 
  def create_or_update_twilio_application!
    app_settings = {
      'FriendlyName' => '%s\'s Application' % self.label,
      'VoiceUrl' => self.twilio_voice_url,
      'VoiceMethod' => 'POST',
      #'StatusCallback' => self.twilio_voice_status_url,
      #'StatusCallbackMethod' => 'POST',
      'SmsUrl' => self.twilio_sms_url,
      'SmsMethod' => 'POST',
      'SmsStatusCallback' => self.twilio_sms_status_url
    }

    if self.twilio_application_sid.blank?
      response = self.twilio_account.applications.create(app_settings)
      self.twilio_application_sid = response.sid
    else
      response = self.twilio_account.applications.get(self.twilio_application_sid).update(app_settings)
    end
  end
  
  def twilio_voice_url
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_call_url( host: 'ticketplease.herokuapp.com' )
  end
  
  def twilio_voice_status_url
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_call_callback_url( host: 'ticketplease.herokuapp.com' )
  end
  
  def twilio_sms_url
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_sms_url( host: 'ticketplease.herokuapp.com' )
  end
  
  def twilio_sms_status_url
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_sms_callback_url( host: 'ticketplease.herokuapp.com' )
  end
  
  def insert_twilio_authentication( url )
  
    # Insert digest authentication
    unless self.twilio_account_sid.blank?
      auth_string = self.account_sid
      auth_string += ':' + self.auth_token unless self.twilio_auth_token.blank?
      url = url.gsub( /(https?:\/\/)/, '\1' + auth_string + '@' )
    end
    
    # Force it to secure HTTPS
    url = url.gsub( /\Ahttp:\/\//, 'https://' )
    
    url
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
  
  def ticket_count_by_status()
    #statuses = self.tickets.today.readonly.select('count(tickets.*) as count, tickets.status').group('tickets.status').each_with_object({}) do |v, h|
    statuses = Ticket.count_by_status_hash( self.tickets.today )
#     statuses = self.tickets.today.count_by_status.readonly.each_with_object({}) do |v, h|
#       h[v.status] = v.count.to_i
#     end
#     return {
#       expired: statuses.fetch( Ticket::EXPIRED, 0 ),
#       denied: statuses.fetch( Ticket::DENIED, 0 ),
#       failed: statuses.fetch( Ticket::FAILED, 0 ),
#       confirmed: statuses.fetch( Ticket::CONFIRMED, 0 ),
#       queued: statuses.fetch( Ticket::QUEUED, 0 ) + statuses.fetch( Ticket::PENDING, 0 ),
#       sent: statuses.fetch( Ticket::CHALLENGE_SENT, 0 )
#     }
  end
  
#   def ticket_statistics( counts=nil )
#     counts ||= self.ticket_count_by_status()
#     total = self.tickets.today.count.to_f
#     return counts.each_with_object({}) do |(k, v), h|
#       h[k] = v.to_f / total * 100.0
#     end
#     return {
#       expired: self.tickets.today.where( status: Ticket::EXPIRED ).count.to_f / total * 100.0,
#       denied: self.tickets.today.where( status: Ticket::DENIED ).count.to_f / total * 100.0,
#       failed: self.tickets.today.where( status: Ticket::FAILED ).count.to_f / total * 100.0,
#       confirmed: self.tickets.today.where( status: Ticket::CONFIRMED ).count.to_f / total * 100.0,
#       queued: self.tickets.today.where( status: [Ticket::QUEUED, Ticket::PENDING] ).count.to_f / total * 100.0,
#       sent: self.tickets.today.where( status: Ticket::CHALLENGE_SENT ).count.to_f / total * 100.0
#     }
#   end
  
  def additive_ticket_statistics
    statistics = self.ticket_statistics
    total = statistics.values.sum
    additive_statistics = {}
    [ :queued, :sent, :confirmed, :expired, :failed, :denied ].each { |key| additive_statistics[key] = additive_statistics.values.sum + statistics[key] }
    additive_statistics.each { |key,value| additive_statistics[key] = value }
    return additive_statistics
  end
  
end
