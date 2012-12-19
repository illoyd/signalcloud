class Message < ActiveRecord::Base
  attr_accessible :our_cost, :provider_cost, :ticket
  
  # attr_encrypted :payload, key: ATTR_ENCRYPTED_SECRET, marshall: true, marshaler: JSON
  belongs_to :ticket, inverse_of: :messages
end
