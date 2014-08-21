module Twilio
  ##
  # Inbound SMSs are POST'ed to the application and arrive as a key-value hash.
  class InboundMessage < ::APISmith::Smash

    # Required fields
    property :sid,          from: :SmsSid,      required: true
    property :account_sid,  from: :AccountSid
    property :from,         from: :From,        required: true
    property :to,           from: :To,          required: true
    property :body,         from: :Body,        required: true
    
    alias_method :internal_number, :to
    alias_method :customer_number, :from

    # Defaulted fields
    property :status,       from: :SmsStatus,   default: Message::RECEIVED_SZ, transformer: Twilio::StatusTransformer
    property :direction,    from: :Direction,   default: Message::IN,          transformer: Twilio::DirectionTransformer
    property :segments,     from: :NumSegments, default: 1,                    transformer: IntegerTransformer

    # Optional fields
    property :price,        from: :Price,       transformer: BigDecimalTransformer
    property :price_unit,   from: :PriceUnit

    # Optional FROM fields
    property :from_city,    from: :FromCity
    property :from_state,   from: :FromState
    property :from_zip,     from: :FromZip
    property :from_country, from: :FromCountry

    # Optional TO fields
    property :to_city,      from: :ToCity
    property :to_state,     from: :ToState
    property :to_zip,       from: :ToZip
    property :to_country,   from: :ToCountry

    # Optional DATE fields
    property :created_at,   from: :DateCreated, transformer: TimeTransformer
    property :updated_at,   from: :DateUpdated, transformer: TimeTransformer
    property :sent_at,      from: :DateSent,    transformer: TimeTransformer
    
    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
    delegate :inbound?, :outbound?, to: :direction
  end
end