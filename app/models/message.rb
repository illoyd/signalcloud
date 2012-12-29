class Message < ActiveRecord::Base
  attr_accessible :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid
  
  before_save :update_costs
  
  ##
  # Encrypted payload. Serialised using JSON
  attr_encrypted :payload, key: ATTR_ENCRYPTED_SECRET, marshal: true, marshaler: JSON

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
  # Update costs based on message payload from provider
  def update_costs

    # Update the provider costs based on the message payload, if available
    self.provider_cost = self.internal_provider_cost unless self.internal_provider_cost.nil?

    # Do not update if our cost is already defined, or the provider cost is not defined
    if self.our_cost.nil? && !self.provider_cost.nil? && ( Numeric(self.provider_cost) != nil rescue false )
      # Get the current account plan
      plan = self.ticket.appliance.account.account_plan
      
      # Update our costs based upon the direction of the message
      self.our_cost = case self.direction
        when 'outbound-api'
          plan.calculcate_outbound_sms_cost( self.provider_cost )
        when 'inbound-api'
          plan.calculate_inbound_sms_cost( self.provider_cost )
      end
    end

  end
  
  ##
  # Cost of this message, combining provider and own charges
  def cost
    return self.our_cost + self.provider_cost
  end
  
  ##
  # Caches the payload, as frequent accesses to the encrypted, marshalled payload will slow down processing
  def cached_payload
    return (@cached_payload ||= self.payload.try(:with_indifferent_access))
  end
  
  ##
  # Shortcut to access the payload's 'body' parameter
  def body
    return self.cached_payload[:body]
  end
  
  ##
  # Shortcut to access the payload's 'to' parameter
  def to_number
    return self.cached_payload[:to]
  end
  
  ##
  # Shortcut to access the payload's 'from' parameter
  def from_number
    return self.cached_payload[:from]
  end

  ##
  # Shortcut to access the payload's 'direction' parameter
  def direction
    return self.cached_payload[:direction]
  end
  
  ##
  # Internal cost
  def internal_provider_cost
    return self.cached_payload[:price]
  end
  
end
