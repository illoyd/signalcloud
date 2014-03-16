class TwilioCommunicationGateway < CommunicationGateway

  # Error constants
  ERROR_INVALID_TO = 101
  ERROR_INVALID_FROM = 102
  ERROR_BLACKLISTED_TO = 105
  ERROR_NOT_SMS_CAPABLE = 103
  ERROR_CANNOT_ROUTE = 104
  ERROR_SMS_QUEUE_FULL = 106
  ERROR_INTERNATIONAL = 107
  ERROR_MISSING_BODY = 108
  ERROR_BODY_TOO_LARGE = 109
  ERROR_UNKNOWN = 127
  ERROR_STATUSES = [ ERROR_INVALID_TO, ERROR_INVALID_FROM, ERROR_BLACKLISTED_TO, ERROR_NOT_SMS_CAPABLE, ERROR_CANNOT_ROUTE, ERROR_SMS_QUEUE_FULL, ERROR_INTERNATIONAL, ERROR_MISSING_BODY, ERROR_BODY_TOO_LARGE, ERROR_UNKNOWN ]
  CRITICAL_ERRORS = [ ERROR_MISSING_BODY, ERROR_BODY_TOO_LARGE, ERROR_INTERNATIONAL ]

  ##
  # Determine if this organization has an authorised Twilio account.
  def has_twilio_account?
    !( self.twilio_account_sid.blank? or self.twilio_auth_token.blank? )
  end
  
  ##
  # Determine if this organization has a configured Twilio application.
  def has_twilio_application?
    return !self.remote_application.blank?
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
  
  alias_method :signature_validator, :twilio_validator
  
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
  
  ##
  # Send an SMS using the Twilio API.
  def send_message!( to_number, from_number, body, options={} )
  
    raise SignalCloud::InvalidToNumberCommunicationGatewayError.new(self) if to_number.blank?
    raise SignalCloud::InvalidFromNumberCommunicationGatewayError.new(self) if from_number.blank?
    raise SignalCloud::InvalidMessageBodyCommunicationGatewayError.new(self) if body.blank?
  
    to_number = self.class.prepend_plus(to_number)
    from_number = self.class.prepend_plus(from_number)
    payload = {
      to: to_number,
      from: from_number,
      body: body
    }
    
    payload[:status_callback] = self.twilio_sms_status_url if options.fetch( :default_callback, false )

    begin
      response = self.twilio_account.sms.messages.create( payload )
      return case options.fetch( :response_format, :smash )
        when :smash
          response.to_property_smash
        when :hash
          response.to_property_hash
        else
          response
      end

    rescue Twilio::REST::RequestError => ex
      case ex.code
        when Twilio::ERR_INVALID_TO_PHONE_NUMBER, Twilio::ERR_SMS_TO_REQUIRED, Twilio::ERR_TO_PHONE_NUMBER_NOT_VALID_MOBILE
          raise SignalCloud::InvalidToNumberCommunicationGatewayError.new self
  
        when Twilio::ERR_INVALID_FROM_PHONE_NUMBER, Twilio::ERR_SMS_FROM_REQUIRED
          raise SignalCloud::InvalidFromNumberCommunicationGatewayError.new self
  
        when Twilio::ERR_SMS_BODY_EXCEEDS_MAXIMUM_LENGTH, Twilio::ERR_SMS_BODY_REQUIRED
          raise SignalCloud::InvalidMessageBodyCommunicationGatewayError.new self
  
        when Twilio::ERR_TO_PHONE_NUMBER_CANNOT_RECEIVE_SMS, Twilio::ERR_TO_PHONE_NUMBER_IS_BLACKLISTED
          raise SignalCloud::MessageDeliveryCommunicationGatewayError.new self
  
        when Twilio::ERR_INTERNATIONAL_NOT_ENABLED, Twilio::ERR_FROM_PHONE_NUMBER_NOT_SMS_CAPABLE
          raise SignalCloud::CommunicationGatewayConfigurationError.new self
  
        else
          raise SignalCloud::CommunicationGatewayError.new self
      end

    end
  end

  alias_method :send_sms!, :send_message!

  def purchase_number!( phone_number )
    pn = self.class.prepend_plus(phone_number.number)
    results = self.twilio_account.incoming_phone_numbers.create( { phone_number: pn, application_sid: self.remote_application } )
    phone_number.provider_sid = results.sid
    results
  end
  
  def unpurchase_number!( phone_number )
    phone_number(phone_number.provider_sid).delete
  end
  
  def update_number!( phone_number )
    phone_number(phone_number.provider_sid).update(assemble_phone_number_data phone_number)
  end
  
  ##
  # Translate a given Twilio error message into a conversation status message
  def self.translate_twilio_error_to_conversation_status( error_code )
    return case error_code
      when Twilio::ERR_INVALID_TO_PHONE_NUMBER, Twilio::ERR_SMS_TO_REQUIRED
        ERROR_INVALID_TO
      when Twilio::ERR_INVALID_FROM_PHONE_NUMBER, Twilio::ERR_SMS_FROM_REQUIRED
        ERROR_INVALID_FROM
      when Twilio::ERR_FROM_PHONE_NUMBER_NOT_SMS_CAPABLE, Twilio::ERR_TO_PHONE_NUMBER_NOT_VALID_MOBILE
        ERROR_NOT_SMS_CAPABLE
      when Twilio::ERR_FROM_PHONE_NUMBER_EXCEEDED_QUEUE_SIZE
        ERROR_SMS_QUEUE_FULL
      when Twilio::ERR_TO_PHONE_NUMBER_CANNOT_RECEIVE_SMS
        ERROR_CANNOT_ROUTE
      when Twilio::ERR_TO_PHONE_NUMBER_IS_BLACKLISTED
        ERROR_BLACKLISTED_TO
      when Twilio::ERR_INTERNATIONAL_NOT_ENABLED
        ERROR_INTERNATIONAL
      when Twilio::ERR_SMS_BODY_REQUIRED
        ERROR_MISSING_BODY
      when Twilio::ERR_SMS_BODY_EXCEEDS_MAXIMUM_LENGTH
        ERROR_BODY_TOO_LARGE
      else
        ERROR_UNKNOWN
      end
  end

protected

  def assemble_phone_number_data( phone_number )
    # Assemble common data
    data = {
      voice_application_sid: self.remote_application,
      sms_application_sid: self.remote_application
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
    self.updated_remote_at = Time.now
  end
  
  def update_remote
    self.update_twilio_account!
    self.update_twilio_application!
    self.updated_remote_at = Time.now
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
    self.remote_application = response.sid
    return response
  end
  
  ##
  # Update the Twilio application.
  def update_twilio_application!
    raise SignalCloud::MissingTwilioAccountError.new(self) unless self.has_twilio_account?
    raise SignalCloud::MissingTwilioApplicationError.new(self) unless self.has_twilio_application?

    return self.twilio_account.applications.get(self.remote_application).update(self.assemble_twilio_application_data)
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
