class TwilioCommunicationGateway < CommunicationGateway

  alias_method :twilio_account_sid,  :remote_sid
  alias_method :twilio_account_sid=, :remote_sid=

  alias_method :twilio_auth_token,  :remote_token
  alias_method :twilio_auth_token=, :remote_token=

  alias_method :twilio_application,  :remote_application
  alias_method :twilio_application=, :remote_application=
  
  alias_method :twilio_application_sid,  :remote_application
  alias_method :twilio_application_sid=, :remote_application=
  
  ##
  # Determine if this organization has an authorised Twilio account.
  def has_twilio_account?
    !( self.twilio_account_sid.blank? or self.twilio_auth_token.blank? )
  end
  
  ##
  # Determine if this organization has a configured Twilio application.
  def has_twilio_application?
    return !self.twilio_application.blank?
  end
  
  ##
  # Return a Twilio Client.
  def twilio_client(reload=false)
    @twilio_client = nil if reload
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    @twilio_client ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
    return @twilio_client
  end
  
  ##
  # Return a Twilio Organization.
  def twilio_account
    return self.twilio_client.account
  end
  
  alias_method :remote_instance, :twilio_account

  ##
  # Return a Twilio Validator.
  def twilio_validator
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
    return @twilio_validator
  end
  
  def twilio_voice_url
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_call_url
  end
  
  def twilio_voice_status_url
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_call_update_url
  end
  
  def twilio_sms_url
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_sms_url
  end
  
  def twilio_sms_status_url
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_sms_update_url
  end
  
  def message( sid )
    self.twilio_account.messages.get( sid )
  end
  
  def phone_number( sid )
    self.twilio_account.incoming_phone_numbers.get( sid )
  end
  
  def self.prepend_plus( number )
    '+' + number unless number.start_with? '+'
  end
  
  ##
  # Send an SMS using the Twilio API.
  def send_sms!( to_number, from_number, body, options={} )
    to_number = self.class.prepend_plus(to_number)
    from_number = self.class.prepend_plus(from_number)
    payload = {
      to: to_number,
      from: from_number,
      body: body
    }
    
    payload[:status_callback] = self.twilio_sms_status_url if options.fetch( :default_callback, false )

    response = self.twilio_account.sms.messages.create( payload )
    return case options.fetch( :response_format, :raw )
      when :smash
        response.to_property_smash
      when :hash
        response.to_property_hash
      else
        response
    end
  end
  
  def purchase_number!( phone_number )
    pn = self.class.prepend_plus(phone_number.number)
    results = self.twilio_account.incoming_phone_numbers.create( { phone_number: pn, application_sid: self.twilio_application_sid } )
    phone_number.provider_sid = results.sid
    results
  end
  
  def unpurchase_number!( phone_number )
    phone_number(phone_number.provider_sid).delete
  end
  
  def update_number!( phone_number )
    phone_number(phone_number.provider_sid).post(assemble_phone_number_data phone_number)
  end
  
protected

  def assemble_phone_number_data( phone_number )
    # Assemble common data
    data = {
      voice_application_sid: self.twilio_application_sid,
      sms_application_sid: self.twilio_application_sid
    }
    
    # Insert existing record data
    unless phone_number.provider_sid.blank?
      data[:sid] = phone_number.provider_sid

    # Insert new record data
    else
      data[:phone_number] = phone_number.number
    end
    
    data
  end
  
  def create_remote
    self.create_twilio_account!
    self.create_twilio_application!
    self.updated_remote_at = DateTime.now
  end
  
  def update_remote
    self.update_twilio_account!
    self.update_twilio_application!
    self.updated_remote_at = DateTime.now
  end

  ##
  # Create a Twilio sub-organization.
  def create_twilio_account!
    raise SignalCloud::TwilioAccountAlreadyExistsError.new(self) if self.has_twilio_account?
    response = Twilio.master_client.accounts.create(self.assemble_twilio_account_data)
    self.twilio_account_sid = response.sid
    self.twilio_auth_token = response.auth_token
    return response
  end
  
  ##
  # Update a Twilio sub-organization.
  def update_twilio_account!
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    response = Twilio.master_client.accounts.get(self.remote_sid).update(self.assemble_twilio_account_data)
    return response
  end
  
  ##
  # Create the Twilio application.
  def create_twilio_application!
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    raise SignalCloud::TwilioApplicationAlreadyExistsError.new(self) if self.has_twilio_application?

    response = self.twilio_account.applications.create(self.assemble_twilio_application_data)
    self.twilio_application_sid = response.sid
    return response
  end
  
  ##
  # Update the Twilio application.
  def update_twilio_application!
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    raise SignalCloud::MissingTwilioApplicationError.new(self) unless self.has_twilio_application?

    return self.twilio_account.applications.get(self.twilio_application_sid).update(self.assemble_twilio_application_data)
  end

  def assemble_twilio_account_data( options={} )
    return {
      'FriendlyName' => self.organization.try(:label) || '[NEW]'
    }.merge(options)
  end

  def assemble_twilio_application_data( options={} )
    return {
      'FriendlyName' => '%s\'s Application' % [ self.organization.try(:label) || '[NEW]' ],

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

  def insert_twilio_authentication( url )
  
    # Insert digest authentication
    if self.organization.try( :sid )
      auth_string = self.organization.sid
      auth_string += ':' + self.organization.auth_token unless self.organization.auth_token.blank?
      url = url.gsub( /(https?:\/\/)/, '\1' + auth_string + '@' )
    end
    
    # Force it to secure HTTPS
    return url.gsub( /\Ahttp:\/\//, 'https://' )
  end

end
