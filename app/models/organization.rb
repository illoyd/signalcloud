class Organization < ActiveRecord::Base
  include Workflow
  
  workflow do
    state :trial do
      event :upgrade, transition_to: :ready
      event :enqueue_upgrade, transition_to: :pending_upgrade
    end
    state :pending_upgrade do
      event :upgrade, transition_to: :ready
    end
    state :ready do
      event :suspend, transition_to: :suspended
      event :cancel, transition_to: :cancelled
      event :upgrade, transition_to: :ready
    end
    state :suspended do
      event :upgrade, transition_to: :ready
      event :enqueue_upgrade, transition_to: :pending_upgrade
      event :cancel, transition_to: :cancelled
    end
    state :cancelled
  end
  
  # Encrypted attributes
  # attr_encrypted :braintree_id, key: ATTR_ENCRYPTED_SECRET

  # References
  has_many :user_roles, inverse_of: :organization
  has_many :users, through: :user_roles

  has_one :account_balance, inverse_of: :organization, autosave: true, dependent: :destroy
  
  has_one :accounting_gateway, inverse_of: :organization
  has_one :communication_gateway, inverse_of: :organization
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
  delegate :has_twilio_application?, :twilio_client, :twilio_account, :twilio_account_sid, :twilio_validator, :send_sms!, to: :communication_gateway
  delegate :freshbooks_id, to: :accounting_gateway

  def ensure_sid_and_token
    self.sid ||= SecureRandom.hex(16)
    self.auth_token ||= SecureRandom.hex(16)
  end
  
  def ensure_account_balance
    self.build_account_balance if self.account_balance.nil?
  end

#   def status
#     tests = [ self.has_client?, self.has_communication_gateway?, self.has_payment_gateway? ]
#     return case
#       when tests.all? { |x| x }
#         READY
#       when tests.any? { |x| x }
#         PENDING
#       else
#         TRIAL
#     end
#   end
#   
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
  
  def has_communication_gateway?
    !self.communication_gateway.nil?
  end
  
  def has_payment_gateway?
    !self.payment_gateway.nil?
  end

#   ##
#   # Determine if this organization has an authorised Twilio account.
#   def has_twilio_account?
#     !( self.twilio_account_sid.blank? or self.twilio_auth_token.blank? )
#   end
#   
#   ##
#   # Determine if this organization has a configured Twilio application.
#   def has_twilio_application?
#     return !self.twilio_application_sid.blank?
#   end
#   
#   ##
#   # Return a Twilio Client.
#   def twilio_client
#     raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
#     @twilio_client ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
#     return @twilio_client
#   end
#   
#   ##
#   # Return a Twilio Organization.
#   def twilio_account
#     return self.twilio_client.account
#   end
#   
#   ##
#   # Return a Twilio Validator.
#   def twilio_validator
#     raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
#     @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
#     return @twilio_validator
#   end
#   
#   def create_twilio_account
#     begin
#       return self.create_twilio_account!
#     rescue SignalCloud::TwilioAccountAlreadyExistsError
#       return nil
#     end
#   end
#   
#   ##
#   # Create a Twilio sub-organization.
#   def create_twilio_account!
#     raise SignalCloud::TwilioAccountAlreadyExistsError.new(self) if self.has_twilio_account?
#     response = Twilio.master_client.accounts.create( 'FriendlyName' => self.label )
#     self.twilio_account_sid = response.sid
#     self.twilio_auth_token = response.auth_token
#     # self.save!
#     return response
#   end
#   
#   ##
#   # Create, or update if it exists, the Twilio application used for this organization.
#   def create_or_update_twilio_application
#     return self.twilio_application_sid.blank? ? self.create_twilio_application : self.update_twilio_application
#   end
#   
#   def create_twilio_application
#     begin
#       return self.create_twilio_application!
#     rescue SignalCloud::TwilioApplicationAlreadyExistsError
#       return nil
#     end
#   end
#   
#   def create_twilio_application!
#     raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
#     raise SignalCloud::TwilioApplicationAlreadyExistsError.new(self) unless self.twilio_application_sid.blank?
# 
#     response = self.twilio_account.applications.create(self.twilio_application_configuration)
#     self.twilio_application_sid = response.sid
#     return response
#   end
#   
#   def update_twilio_application
#     begin
#       return self.update_twilio_application!
#     rescue SignalCloud::MissingTwilioApplicationError
#       return nil
#     end
#   end
#   
#   def update_twilio_application!
#     raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
#     raise SignalCloud::MissingTwilioApplicationError.new(self) unless self.has_twilio_application?
# 
#     return self.twilio_account.applications.get(self.twilio_application_sid).update(self.twilio_application_configuration)
#   end
#   
#   def twilio_application_configuration( options={} )
#     return {
#       'FriendlyName' => '%s\'s Application' % self.label,
# 
#       'VoiceUrl' => self.twilio_voice_url,
#       'VoiceMethod' => 'POST',
# 
#       'VoiceFallbackUrl' => self.twilio_voice_url,
#       'VoiceFallbackMethod' => 'POST',
# 
#       'StatusCallback' => self.twilio_voice_status_url,
#       'StatusCallbackMethod' => 'POST',
# 
#       'SmsUrl' => self.twilio_sms_url,
#       'SmsMethod' => 'POST',
#       
#       'SmsFallbackUrl' => self.twilio_sms_url,
#       'SmsFallbackMethod' => 'POST',
# 
#       'SmsStatusCallback' => self.twilio_sms_status_url
#     }.merge(options)
# 
#   end
#   
#   def twilio_voice_url
#     raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
#     self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_call_url
#   end
#   
#   def twilio_voice_status_url
#     raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
#     self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_call_update_url
#   end
#   
#   def twilio_sms_url
#     raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
#     self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_sms_url
#   end
#   
#   def twilio_sms_status_url
#     raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
#     self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_sms_update_url
#   end
#   
#   def insert_twilio_authentication( url )
#   
#     # Insert digest authentication
#     unless self.twilio_account_sid.blank?
#       auth_string = self.sid
#       auth_string += ':' + self.auth_token unless self.auth_token.blank?
#       url = url.gsub( /(https?:\/\/)/, '\1' + auth_string + '@' )
#     end
#     
#     # Force it to secure HTTPS
#     return url.gsub( /\Ahttp:\/\//, 'https://' )
#   end
# 
#   ##
#   # Send an SMS using the Twilio API.
#   def send_sms( to_number, from_number, body, options={} )
#     payload = {
#       to: to_number,
#       from: from_number,
#       body: body
#     }
#     
#     payload[:status_callback] = self.twilio_sms_status_url if options.fetch( :default_callback, false )
# 
#     response = self.twilio_account.sms.messages.create( payload )
#     return case options.fetch( :response_format, :raw )
#       when :smash
#         response.to_property_smash
#       when :hash
#         response.to_property_hash
#       else
#         response
#     end
#   end
  
#   def has_freshbooks_client?
#     !self.freshbooks_id.blank?
#   end
# 
#   ##
#   # Get the current client's FreshBook organization, using the FreshBook global module.
#   # In FreshBooks parlance, this is a 'Client' object.
#   def freshbooks_client
#     raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
#     response = FreshBooks.account.client.get(client_id: self.freshbooks_id)
#     raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
#     response['client']
#   end
#   
#   ##
#   # Helper method to create or update as necessary
#   def create_or_update_freshbooks_client!
#     self.has_freshbooks_client? ? self.update_freshbooks_client! : self.create_freshbooks_client!
#   end
#   
#   ##
#   # Create a new FreshBooks client for this organization. This method will throw an error if a FreshBooks client already exists.
#   def create_freshbooks_client!
#     raise SignalCloud::FreshBooksClientAlreadyExistsError.new(self) if self.has_freshbooks_client?
#     raise SignalCloud::MissingContactDetailsError.new(self) if self.contact_address.nil?
#     
#     # Instruct FreshBooks API to create the organization, then save the resulting ID
#     response = FreshBooks.account.client.create(self.assemble_freshbooks_client_data)
#     
#     # If this is a duplicate, try to find and re-use the account based on the email
#     if response.fetch('code', 0) == 40068.to_s
#       response = self.find_freshbooks_client_by_email
# 
#     # Otherwise, raise error
#     else
#       raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
#     end
#     
#     # Finally, save!
#     self.freshbooks_id = response['client_id']
#     self.save!
#   end
#   
#   def update_freshbooks_client!
#     raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
#     raise SignalCloud::MissingContactDetailsError.new( self ) if self.contact_address.nil?
# 
#     # Instruct FreshBooks API to update the organization, then save the resulting ID
#     response = FreshBooks.account.client.update(self.assemble_freshbooks_client_data)
#     raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
#     self.save!
#   end
#   
#   def find_freshbooks_client_by_email
#     raise SignalCloud::MissingContactDetailsError.new( self ) if self.contact_address.nil?
#     response = FreshBooks.account.client.list({ email: self.contact_address.email })
#     raise SignalCloud::FreshBooksError.new( 'API Error: %s (%i)' % [response['error'], response['code']], response['code'] ) unless response.success?
#     return response.fetch('clients', {}).fetch('client', nil)
#   end
#   
#   def assemble_freshbooks_client_data( additional_data={} )
#     # Construct the complete client dataset to be passed to FreshBooks
#     client_data = {
#       organization: self.label,
#       currency_code: FreshBooks::DEFAULT_CURRENCY
#     }
#     
#     # Add client data if already set
#     client_data[:client_id] = self.freshbooks_id if self.has_freshbooks_client?
#     
#     # Insert primary address if appropriate
#     unless self.billing_address.nil?
#       client_data.merge!({
#         # Add billing contact
#         first_name: self.billing_address.first_name,
#         last_name:  self.billing_address.last_name,
#         username:   self.billing_address.email,
#         email:      self.billing_address.email,
#         work_phone: self.billing_address.work_phone,
# 
#         # Add address
#         p_street1:  self.billing_address.line1,
#         p_street2:  self.billing_address.line2,
#         p_city:     self.billing_address.city,
#         p_state:    self.billing_address.region,
#         p_country:  self.billing_address.country,
#         p_code:     self.billing_address.postcode
#       })
#     end
#     
#     # Insert secondary address if needed
#     unless self.contact_address.nil?
#       client_data.merge!({
#         s_street1:  self.contact_address.line1,
#         s_street2:  self.contact_address.line2,
#         s_city:     self.contact_address.city,
#         s_state:    self.contact_address.region,
#         s_country:  self.contact_address.country,
#         s_code:     self.contact_address.postcode
#       })
#     end
#     
#     # Insert VAT data if appropriate
#     client_data[:vat_name]   unless self.vat_name.blank?
#     client_data[:vat_number] unless self.vat_number.blank?
#     
#     # If additional data is passed
#     if additional_data.is_a? Hash
#       client_data.merge! additional_data
#     end
#     
#     # Wrap in a client identifier
#     { client: client_data }
#   end
#   
#   ##
#   # Generate a new FreshBooks invoice.
#   def build_next_invoice( to_date=nil )
#     to_date ||= DateTime.yesterday.end_of_day
#     return self.invoices.build date_to: to_date
#   end
#   
#   ##
#   # Generate a new FreshBooks invoice.
#   def create_next_invoice( to_date=nil )
#     invoice = self.build_next_invoice(to_date)
#     invoice.save
#     invoice
#   end
#   
#   ##
#   # Build, prepare, and settle the next invoice
#   def settle_next_invoice( to_date=nil )
#     invoice = self.build_next_invoice( to_date )
#     invoice.prepare!
#     return invoice
#   end
#   
#   ##
#   # Build, prepare, and settle the next invoice
#   def settle_next_invoice( to_date=nil )
#     invoice = self.build_next_invoice( to_date )
#     invoice.settle!
#     return invoice
#   end
#   
  ##
  # Return the date of the last invoice, or the first ledger_entry
  def last_invoice_date
    self.invoices.maximum('date_to') #.to_time rescue nil
  end
#   
#   def assemble_freshbooks_payment_data( amount )
#     { client_id: self.freshbooks_id, amount: amount, type: 'Credit' }
#   end
#   
#   def record_freshbooks_payment( amount )
#     raise SignalCloud::MissingFreshBooksClientError.new(self) unless self.has_freshbooks_client?
#     data = assemble_freshbooks_payment_data( amount )
#     FreshBooks.account.payment.create({ payment: data })
#   end
#   
#   def freshbooks_credits
#     credits = self.freshbooks_client['credits']
#     credits = [ credits ] unless credits.is_a? Array
#     credits.each_with_object(HashWithIndifferentAccess.new) do |credit, h|
#       currency = credit['credit']['currency']
#       amount = BigDecimal.new credit['credit']['__content__']
#       h[currency] = amount
#     end
#   end

private

  def enqueue_upgrade
    Jobs.push UpgradeOrganizationJob.new( self.id )
  end
  
  def upgrade
    # Update SMS data if needed
    self.create_or_update_communication_gateway

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
    self.communication_gateway.cancel!
  end

end
