module Twilio
  class Message < ::APISmith::Smash
  
    # Required fields
    property :sid,        required: true
    property :account_sid
  
    property :created_at, from: :date_created, transformer: TimeTransformer
    property :updated_at, from: :date_updated, transformer: TimeTransformer
    property :sent_at,    from: :date_sent,    transformer: TimeTransformer
  
    property :to,         required: true
    alias_method :customer_number, :to
  
    property :from,       required: true
    alias_method :internal_number, :from
  
    property :body,       required: true
    
    property :status,     required: true, transformer: Twilio::StatusTransformer
    property :direction,  required: true, transformer: Twilio::DirectionTransformer
  
    property :price,      transformer: BigDecimalTransformer
    property :price_unit
  
    property :segments,   from: :num_segments
  
    property :api_version
  
    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
    delegate :inbound?, :outbound?, to: :direction
    
  end
end