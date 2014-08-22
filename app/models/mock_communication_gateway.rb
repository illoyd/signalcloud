class MockCommunicationGateway < CommunicationGateway
  INVALID_TO_NUMBERS   = [ Twilio::INVALID_NUMBER, Twilio::INVALID_CANNOT_ROUTE_TO_NUMBER, Twilio::INVALID_INTERNATIONAL_NUMBER, Twilio::INVALID_BLACKLISTED_NUMBER ]
  INVALID_FROM_NUMBERS = [ Twilio::INVALID_NUMBER, Twilio::INVALID_NOT_SMS_CAPABLE_FROM_NUMBER, Twilio::INVALID_FULL_SMS_QUEUE_NUMBER, Twilio::INVALID_INTERNATIONAL_NUMBER, Twilio::INVALID_NOT_SMS_CAPABLE_TO_NUMBER ]

  def memorize( obj )
    self.memory[obj.sid] = obj
  end

  def message( sid )
    self.memory[sid]
  end
  
  def send_message!( to_number, from_number, body, options={} )
    raise SignalCloud::InvalidToNumberCommunicationGatewayError.new(self) if to_number.blank?
    raise SignalCloud::InvalidFromNumberCommunicationGatewayError.new(self) if from_number.blank?
    raise SignalCloud::InvalidMessageBodyCommunicationGatewayError.new(self) if body.blank?

    # Normalise and test to number    
    to_number = normalize_phone_number(to_number)
    raise SignalCloud::InvalidToNumberCommunicationGatewayError.new(self) if INVALID_TO_NUMBERS.include?(to_number)

    # Normalise and test from number
    from_number = normalize_phone_number(from_number)
    raise SignalCloud::InvalidFromNumberCommunicationGatewayError.new(self) if INVALID_FROM_NUMBERS.include?(from_number)

    status = options.fetch(:status, select_status(to_number, from_number))

    msg = MockMessage.new(
      sid:         SecureRandom.hex(4),
      account_sid: self.remote_sid,
      to:          to_number,
      from:        from_number,
      body:        body,
      direction:   ::Message::OUT,
      status:      status,
      segments:    ( body.length.to_f / 160 ).ceil,
      price:       ( status == 'sent' ? '0.01' : nil ),
      price_unit:  ( status == 'sent' ? 'USD' : nil ),
      created_at:  options.fetch(:created_at, Time.now),
      updated_at:  options.fetch(:updated_at, Time.now),
      sent_at:     ( status == 'sent' ? Time.now : nil )
    )
    memorize( msg )
    msg
  end
  
  # TODO: Remove this alias
  alias_method :send_sms!, :send_message!
  
  def purchase_number!( phone_number )
    phone_number = normalize_phone_number( phone_number )
    # TODO
  end
  
  def unpurchase_number!( phone_number )
    phone_number = normalize_phone_number( phone_number )
    # TODO
  end
  
  def update_number!( phone_number )
    phone_number = normalize_phone_number( phone_number )
    # TODO
  end

  def valid_signature?( signature, params )
    self.signature_validator.valid?( signature, params )
  end
  
  def signature_validator
    return Object.new do |validator|
      def valid?( signature, params )
        return true
      end
    end
  end

  class MockMessage < APISmith::Smash

    # Required fields
    property :sid,        required: true
    property :account_sid

    property :created_at, transformer: TimeTransformer
    property :updated_at, transformer: TimeTransformer
    property :sent_at,    transformer: TimeTransformer

    property :to,         required: true
    alias_method :customer_number, :to

    property :from,       required: true
    alias_method :internal_number, :from

    property :body,       required: true
    
    property :status,     required: true, transformer: StringInquirerTransformer
    property :direction,  required: true, transformer: StringInquirerTransformer

    property :price,      transformer: BigDecimalTransformer
    property :price_unit

    property :segments,   from: :num_segments

    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
    delegate :inbound?, :outbound?, to: :direction

  end

protected

  def select_status(to_number, from_number)
    if INVALID_FROM_NUMBERS.include?(from_number) || INVALID_TO_NUMBERS.include?(to_number)
      ::Message::FAILED_SZ
    else
      ::Message::SENT_SZ
    end
  end
  
  def normalize_phone_number( phone_number )
    phone_number = phone_number.number if phone_number.is_a? PhoneNumber
    "+#{Country.normalize_phone_number(phone_number)}"
  end
  
  def memory
    @@memory ||= {}
  end
  
end
