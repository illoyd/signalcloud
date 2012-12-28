class Message < ActiveRecord::Base
  attr_accessible :our_cost, :provider_cost, :ticket_id, :text
  
  attr_encrypted :payload, key: ATTR_ENCRYPTED_SECRET, marshall: true, marshaler: JSON
  attr_encrypted :text, key: ATTR_ENCRYPTED_SECRET

  belongs_to :ticket, inverse_of: :messages
end
