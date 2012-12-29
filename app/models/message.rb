class Message < ActiveRecord::Base
  attr_accessible :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid
  
  ##
  # Encrypted payload. Serialised using JSON
  attr_encrypted :payload, key: ATTR_ENCRYPTED_SECRET, marshall: true, marshaler: JSON

  ##
  # Parent ticket, of which this message is part of the conversation
  belongs_to :ticket, inverse_of: :messages
  
  # Validations
  validates_numericality_of :our_cost, allow_null: true
  validates_numericality_of :provider_cost, allow_null: true
  validates_presence_of :ticket
  validates_presence_of :payload
  validates_length_of :twilio_id, is: TWILIO_SID_LENGTH
  validates_uniqueness_of :twilio_sid
  
  ##
  # Caches the payload, as frequent accesses to the encrypted, marshalled payload will slow down processing
  def cached_payload
    return (@cached_payload ||= self.payload)
  end
  
  ##
  # Text shortcut to access the payload's text parameter
  def text
    return self.cached_payload['text']
  end
end
