class UnsolicitedCall < ActiveRecord::Base
  belongs_to :phone_number, inverse_of: :unsolicited_calls
  has_one :ledger_entry, as: :item

  before_save :update_ledger_entry

  attr_accessible :twilio_call_sid, :action_content, :action_taken, :action_taken_at, :customer_number, :call_content, :received_at, :provider_price, :our_price
  serialize :call_content, JSON
  serialize :action_content, JSON
  
  validates_presence_of :customer_number, :call_content, :received_at
  validates_inclusion_of :action_taken, in: PhoneNumber::CALL_ACTIONS
  
  delegate :account, to: :phone_number
  
  ##
  # Query the Twilio status of this message. The standard returned parameters are as follows:
  #   +sid+               A 34 character string that uniquely identifies this resource.
  #   +parent_call_sid+   A 34 character string that uniquely identifies the call that created this leg.
  #   +date_created+      The date that this resource was created, given as GMT in RFC 2822 format.
  #   +date_updated+      The date that this resource was last updated, given as GMT in RFC 2822 format.
  #   +account_sid+       The unique id of the Account responsible for creating this call.
  #   +to+                The phone number or Client identifier that received this call. Phone numbers are in E.164 format (e.g. +16175551212). Client identifiers are formatted client:name.
  #   +from+              The phone number or Client identifier that made this call. Phone numbers are in E.164 format (e.g. +16175551212). Client identifiers are formatted client:name.
  #   +phone_number_sid+  If the call was inbound, this is the Sid of the IncomingPhoneNumber that received the call. If the call was outbound, it is the Sid of the OutgoingCallerId from which the call was placed.
  #   +status+            A string representing the status of the call. May be queued, ringing, in-progress, completed, failed, busy or no-answer. See 'Call Status Values' below for more information.
  #   +start_time+        The start time of the call, given as GMT in RFC 2822 format. Empty if the call has not yet been dialed.
  #   +end_time+          The end time of the call, given as GMT in RFC 2822 format. Empty if the call did not complete successfully.
  #   +duration+          The length of the call in seconds. This value is empty for busy, failed, unanswered or ongoing calls.
  #   +price+             The charge for this call in USD. Populated after the call is completed. May not be immediately available.
  #   +direction+         A string describing the direction of the call. inbound for inbound calls, outbound-api for calls initiated via the REST API or outbound-dial for calls initiated by a <Dial> verb.
  #   +answered_by+       If this call was initiated with answering machine detection, either human or machine. Empty otherwise.
  #   +forwarded_from+    If this call was an incoming call forwarded from another number, the forwarding phone number (depends on carrier supporting forwarding). Empty otherwise.
  #   +caller_name+       If this call was an incoming call from a phone number with Caller ID Lookup enabled, the caller's name. Empty otherwise.
  #   +uri+               The URI for this resource, relative to https://api.twilio.comment
  def twilio_status
    self.account.twilio_account.calls.get( self.twilio_call_sid )
  end
  
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
    return nil unless self.phone_number && self.account
    value = self.provider_price if value.nil?
    self.account.account_plan.calculate_inbound_call_price( value )
  end

end
