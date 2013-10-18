class MockedCommunicationGateway
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include Workflow
  
  workflow do
    state :new do
      event :create_remote, transitions_to: :ready
    end
    state :ready do
      event :update_remote, transitions_to: :ready
    end
  end
  
  attr_accessor :id, :organization, :remote_sid, :remote_token, :remote_application, :updated_remote_at, :created_at, :updated_at

  validates_presence_of :remote_sid, :remote_token, if: :ready?
  
  def type
    @type ||= self.class.name
  end
  
  def organization_id
    self.organization.id
  end
  
  def remote_instance
    # TODO
  end
  
  def message( sid )
    self.memory[sid]
  end
  
  def phone_number( sid )
    # TODO
  end
  
  def send_message!( to_number, from_number, body, options={} )
    raise SignalCloud::InvalidToNumberCommunicationGatewayError.new(self) if to_number.blank?
    raise SignalCloud::InvalidFromNumberCommunicationGatewayError.new(self) if from_number.blank?
    raise SignalCloud::InvalidMessageBodyCommunicationGatewayError.new(self) if body.blank?
    
    
    mock = options.fetch(mock, {})
    mock = {} if mock == true
    status = mock.fetch(:status, [::Message::PENDING_SZ, ::Message::SENDING_SZ, ::Message::SENT_SZ, ::Message::FAILED_SZ ].sample )

    msg = Message.new(
      sid: SecureRandom.hex(4),
      account_sid: self.remote_sid,
      to: to_number,
      from: from_number,
      body: body,
      direction: ::Message::OUT,
      status: status,
      segments: ( body.length.to_f / 160 ).ceil,
      price: ( status == 'sent' ? '0.01' : nil ),
      price_unit: ( status == 'sent' ? 'USD' : nil ),
      created_at: mock.fetch(:created_at, Time.now),
      updated_at: mock.fetch(:updated_at, Time.now),
      sent_at: ( status == 'sent' ? Time.now : nil )
    )
    memorize( msg )
    msg
  end
  
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

  class Message < APISmith::Smash

    # Required fields
    property :sid,        required: true
    property :account_sid

    property :created_at, transformer: lambda { |v| Time.parse(v) rescue v }
    property :updated_at, transformer: lambda { |v| Time.parse(v) rescue v }
    property :sent_at,    transformer: lambda { |v| Time.parse(v) rescue v }

    property :to,         required: true
    alias_method :customer_number, :to

    property :from,       required: true
    alias_method :internal_number, :from

    property :body,       required: true
    
    property :status,     required: true, transformer: lambda { |v| ActiveSupport::StringInquirer.new(v) rescue v }
    property :direction,  required: true, transformer: lambda { |v| ActiveSupport::StringInquirer.new(v) rescue v }

    property :price,      transformer: lambda { |v| BigDecimal.new v rescue nil }
    property :price_unit

    property :segments,   from: :num_segments

    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
    delegate :inbound?, :outbound?, to: :direction

  end

protected
  
  def normalize_phone_number( phone_number )
    phone_number = phone_number.number if phone_number.is_a? PhoneNumber
    "+#{PhoneTools.normalize(phone_number)}"
  end
  
  def memory
    @memory ||= {}
  end
  
  def memorize( obj )
    self.memory[obj.sid] = obj
  end

end
