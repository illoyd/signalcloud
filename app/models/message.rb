class Message < ActiveRecord::Base
  attr_accessible :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid
  
  ##
  # Encrypted payload. Serialised using JSON
  attr_encrypted :payload, key: ATTR_ENCRYPTED_SECRET, marshall: true, marshaler: JSON

  ##
  # Parent ticket, of which this message is part of the conversation
  belongs_to :ticket, inverse_of: :messages
  
  # Validations
  validates_presence_of :ticket_id, :twilio_sid, :payload
  validates_numericality_of :our_cost, allow_null: true
  validates_numericality_of :provider_cost, allow_null: true
  validates_length_of :twilio_sid, is: TWILIO_SID_LENGTH
  validates_uniqueness_of :twilio_sid
  
  ##
  # Caches the payload, as frequent accesses to the encrypted, marshalled payload will slow down processing
  def cached_payload
    return (@cached_payload ||= self.payload)
  end
  
  ##
  # Shortcut to access the payload's 'body' parameter
  def body
    return self.cached_payload['body']
  end
  
  ##
  # Shortcut to access the payload's 'to' parameter
  def to_number
    return self.cached_payload['to']
  end
  
  ##
  # Shortcut to access the payload's 'from' parameter
  def from_number
    return self.cached_payload['from']
  end
  
end
