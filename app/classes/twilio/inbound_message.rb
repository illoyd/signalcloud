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
    
    # Defaulted fields
    property :status,       from: :SmsStatus,   default: Message::RECEIVED_SZ, transformer: lambda { |v| Twilio::StatusTransformer.transform(v) }
    property :direction,    from: :Direction,   default: Message::IN, transformer: lambda { |v| Twilio::DirectionTransformer.transform(v) }
    property :segments,     from: :NumSegments, default: 1, transformer: lambda { |v| v.to_i rescue 1 }

    # Optional fields
    property :price,        from: :Price,       transformer: lambda { |v| BigDecimal.new(v) rescue nil }
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
    property :created_at,   from: :DateCreated, transformer: lambda { |v| Time.parse(v) rescue nil }
    property :updated_at,   from: :DateUpdated, transformer: lambda { |v| Time.parse(v) rescue nil }
    property :sent_at,      from: :DateSent,    transformer: lambda { |v| Time.parse(v) rescue nil }
    
    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
    delegate :inbound?, :outbound?, to: :direction
  end
end