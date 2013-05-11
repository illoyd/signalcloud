class Organization < ActiveRecord::Base

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
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    @twilio_client ||= Twilio::REST::Client.new self.twilio_account_sid, self.twilio_auth_token
    return @twilio_client
  end
  
  ##
  # Return a Twilio Organization.
  def twilio_account
    return self.twilio_client.account
  end
  
  ##
  # Return a Twilio Validator.
  def twilio_validator
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    @twilio_validator ||= Twilio::Util::RequestValidator.new self.twilio_auth_token
    return @twilio_validator
  end
  
  def create_twilio_account
    begin
      return self.create_twilio_account!
    rescue SignalCloud::TwilioAccountAlreadyExistsError
      return nil
    end
  end
  
  ##
  # Create a Twilio sub-organization.
  def create_twilio_account!
    raise SignalCloud::TwilioAccountAlreadyExistsError.new(self) unless self.twilio_account_sid.blank? and self.twilio_auth_token.blank?
    response = Twilio.master_client.accounts.create( 'FriendlyName' => self.label )
    self.twilio_account_sid = response.sid
    self.twilio_auth_token = response.auth_token
    # self.save!
    return response
  end
  
  ##
  # Create, or update if it exists, the Twilio application used for this organization.
  def create_or_update_twilio_application
    return self.twilio_application_sid.blank? ? self.create_twilio_application : self.update_twilio_application
  end
  
  def create_twilio_application
    begin
      return self.create_twilio_application!
    rescue SignalCloud::TwilioApplicationAlreadyExistsError
      return nil
    end
  end
  
  def create_twilio_application!
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    raise SignalCloud::TwilioApplicationAlreadyExistsError.new(self) unless self.twilio_application_sid.blank?

    response = self.twilio_account.applications.create(self.twilio_application_configuration)
    self.twilio_application_sid = response.sid
    return response
  end
  
  def update_twilio_application
    begin
      return self.update_twilio_application!
    rescue SignalCloud::MissingTwilioApplicationError
      return nil
    end
  end
  
  def update_twilio_application!
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    raise SignalCloud::MissingTwilioApplicationError.new(self) if self.twilio_application_sid.blank?

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
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_call_url
  end
  
  def twilio_voice_status_url
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_call_update_url
  end
  
  def twilio_sms_url
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_inbound_sms_url
  end
  
  def twilio_sms_status_url
    raise SignalCloud::MissingTwilioAccountError.new(self) if self.twilio_account_sid.blank? or self.twilio_auth_token.blank?
    self.insert_twilio_authentication Rails.application.routes.url_helpers.twilio_sms_update_url
  end
  
  def insert_twilio_authentication( url )
  
    # Insert digest authentication
    unless self.twilio_account_sid.blank?
      auth_string = self.sid
      auth_string += ':' + self.auth_token unless self.auth_token.blank?
      url = url.gsub( /(https?:\/\/)/, '\1' + auth_string + '@' )
    end
    
    # Force it to secure HTTPS
    return url.gsub( /\Ahttp:\/\//, 'https://' )
  end

end
