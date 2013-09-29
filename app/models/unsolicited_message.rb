class UnsolicitedMessage < ActiveRecord::Base
  belongs_to :phone_number, inverse_of: :unsolicited_messages
  has_one :ledger_entry, as: :item

  before_save :update_ledger_entry

  #attr_accessible :twilio_sms_sid, :action_content, :action_taken, :action_taken_at, :customer_number, :message_content, :received_at
  serialize :message_content, JSON
  serialize :action_content, JSON

  validates_presence_of :customer_number, :message_content, :received_at
  validates_inclusion_of :action_taken, in: PhoneNumber::MESSAGE_ACTIONS

  delegate :organization, to: :phone_number

  ##
  # Is a price defined for this message?
  def has_price?
    return !(self.our_price.nil? or self.provider_price.nil?)
  end
  
  ##
  # Price of this message, combining provider and own charges.
  def price
    return (self.our_price || 0) + (self.provider_price || 0)
  end
  
  def provider_price=(value)
    super(value)
    self.our_price = value.nil? ? nil : self.calculate_our_price(value)
  end
  
  def update_ledger_entry
    # Is this entry has a price already set...
    if self.has_price?
      self.build_ledger_entry( narrative: LedgerEntry::INBOUND_CALL_NARRATIVE ) if self.ledger_entry.nil?
      self.ledger_entry.value = self.price
    
    # Otherwise, if a ledger entry is already created, nil the value
    elsif not self.ledger_entry.nil?
      self.ledger_entry.value = nil
    end
    
    # Finally, try to save the ledger entry if it exists and this is NOT a new record
    self.ledger_entry.save unless self.ledger_entry.nil? || self.new_record?
  end
  
  def calculate_our_price( value=nil )
    return nil unless self.phone_number && self.organization
    value = self.provider_price if value.nil?
    self.organization.account_plan.calculate_inbound_call_price( value )
  end

end
