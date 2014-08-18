module Twilio
  ##
  # Inbound SMSs are POST'ed to the application and arrive as a key-value hash.
  class MessageStatus < ::APISmith::Smash

    # Required fields
    property :sid,          from: :SmsSid,      required: true
    property :account_sid,  from: :AccountSid
    property :from,         from: :From
    property :to,           from: :To
    property :body,         from: :Body
    property :status,       from: :SmsStatus,   required: true, transformer: Twilio::StatusTransformer

    delegate :sent?, :sending?, :queued?, :received?, :failed?, to: :status
  end
end