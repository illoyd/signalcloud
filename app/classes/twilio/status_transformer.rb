module Twilio
  class StatusTransformer
    SENT     = 'sent'
    SENDING  = 'sending'
    QUEUED   = %w( queued pending )
    RECEIVED = 'received'
    FAILED   = 'failed'
    def self.transform(v)
      ActiveSupport::StringInquirer.new case v.downcase
        when SENT;     ::Message::SENT_SZ
        when SENDING;  ::Message::SENDING_SZ
        when *QUEUED;  ::Message::PENDING_SZ
        when RECEIVED; ::Message::RECEIVED_SZ
        when FAILED;   ::Message::FAILED_SZ
        else raise SignalCloud::TransformError.new( "Unrecognised status: #{v}" )
      end
    end
  end
end