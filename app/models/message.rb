# encoding: UTF-8
class Message < ActiveRecord::Base
  attr_accessible :status, :sent_at, :our_cost, :provider_cost, :conversation_id, :provider_response, :provider_update, :twilio_sid, :message_kind, :to_number, :from_number, :body, :direction
  
  before_save :update_ledger_entry

  SMS_CHARSET_LIST = " @Δ0¡P¿p£_!1AQaq$Φ\"2BRbr¥Γ#3CScsèΛ¤4DTdtéΩ%5EUeuùΠ&6FVfvìΨ'7GWgwòΣ(8HXhxÇΘ)9IYiy\nΞ*:JZjzØ\e+;KÄkäøÆ,<LÖlö\ræ=MÑmñÅß.>NÜnüåÉ/?O§oà-"
  SMS_CHARSET = /\A[ @Δ0¡P¿p£_!1AQaq$Φ"2BRbr¥Γ#3CScsèΛ¤4DTdtéΩ%5EUeuùΠ&6FVfvìΨ'7GWgwòΣ\(8HXhxÇΘ\)9IYiy\nΞ*:JZjzØ\e+;KÄkäøÆ,<LÖlö\ræ=MÑmñÅß.>NÜnüåÉ\/?O§oà-]+\Z/
  SMS_CBS_MAX_LENGTH = 160
  SMS_UTF_MAX_LENGTH = 70
  
  CHALLENGE = 'c'
  REPLY = 'r'
  
  PENDING = 0
  QUEUED = 1
  SENDING = 2
  SENT = 3
  FAILED = 4
  RECEIVED = 5
  
  OPEN_STATUSES = [ PENDING, QUEUED, SENDING ]
  CLOSED_STATUSES = [ SENT, FAILED, RECEIVED ]
  STATUSES = OPEN_STATUSES + CLOSED_STATUSES
  
  DIRECTION_OUT = 0
  DIRECTION_IN = 1
  DIRECTIONS = [ DIRECTION_OUT, DIRECTION_IN ]

  ##
  # Encrypted payload. Serialised using JSON.
  attr_encrypted :provider_response, key: ATTR_ENCRYPTED_SECRET, marshal: true, marshaler: JSON

  ##
  # Encrypted callback. payload. Serialised using JSON.
  attr_encrypted :provider_update, key: ATTR_ENCRYPTED_SECRET, marshal: true, marshaler: JSON

  attr_encrypted :to_number, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :from_number, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :body, key: ATTR_ENCRYPTED_SECRET

  ##
  # Parent conversation, of which this message is part of the conversation.
  belongs_to :conversation, inverse_of: :messages
  
  ##
  # Chain up to parent's organization.
  delegate :organization, :to => :conversation, :allow_nil => true
  
  ##
  # LedgerEntry for this message.
  has_one :ledger_entry, as: :item #, autosave: true

  # Validations
  validates_presence_of :conversation_id #, :twilio_sid
  validates_numericality_of :our_cost, allow_nil: true
  validates_numericality_of :provider_cost, allow_nil: true
  validates_length_of :twilio_sid, is: Twilio::SID_LENGTH, allow_nil: true
  validates_uniqueness_of :twilio_sid, allow_nil: true
  validates_inclusion_of :message_kind, in: [ CHALLENGE, REPLY ], allow_nil: true
  validates_inclusion_of :status, in: STATUSES
  validates_inclusion_of :direction, in: DIRECTIONS
  
  scope :outstanding, where( 'messages.status not in (?)', CLOSED_STATUSES )
  
  ##
  # Is the given string composed solely of basic SMS characters?
  def self.is_sms_charset?( message )
    begin
      !(SMS_CHARSET =~ message).nil?
    rescue # ex => ArgumentError
      false
    end
  end
  
  ##
  # Select the message chunking size, based on SMS character set.
  def self.select_message_chunk_size( message )
    return is_sms_charset?( message ) ? SMS_CBS_MAX_LENGTH : SMS_UTF_MAX_LENGTH
  end
  
  ##
  # Select the regular expression to use, based on the message chunk size.
  def self.select_message_chunking_strategy( message )
    if is_sms_charset?( message )
      /.{1,160}/
    else
      /.{1,70}/
    end
  end
  
  def ledger_entry_narrative( dir=nil )
    dir = self.direction if dir.nil?
    return case dir
      when DIRECTION_OUT; LedgerEntry::OUTBOUND_SMS_NARRATIVE
      when DIRECTION_IN; LedgerEntry::INBOUND_SMS_NARRATIVE
      else; UNKNOWN_NARRATIVE
    end
  end
  
  def update_ledger_entry
    # If provider cost is given, but not our cost, this implies that the message is in a partial state.
    # Force the provider_cost again.
    self.provider_cost = self.provider_cost if !self.provider_cost.nil? and self.our_cost.nil?
    
    # Is this message has a cost set...
    if self.has_cost?
      self.build_ledger_entry( narrative: self.ledger_entry_narrative ) if self.ledger_entry.nil?
      self.ledger_entry.value = self.cost
      self.ledger_entry.settled_at = self.sent_at || DateTime.now
    
    # Otherwise, if a ledger entry is already created, nil the value
    elsif not self.ledger_entry.nil?
      self.ledger_entry.value = nil
      self.ledger_entry.settled_at = nil
    end
    
    # Finally, try to save the ledger entry if it exists and this is NOT a new record
    self.ledger_entry.save unless self.ledger_entry.nil? || self.new_record?
  end
  
  ##
  # Update costs based on message payload from provider
#   def update_costs
#   
#     # Clear the cached payload
#     self.clear_cached_payload()
# 
#     self.update_provider_cost() if self.provider_cost.nil?
#     self.update_our_cost() if self.our_cost.nil?
# 
#     return true
#   end
  
#   def update_provider_cost
#     return unless self.has_provider_price?
#     self.provider_cost = self.provider_price
#   end
  
#   def update_our_cost
#     return unless self.has_provider_price?
#     plan = self.conversation.stencil.organization.account_plan
#     
#     # Update our costs based upon the direction of the message
#     self.our_cost = case self.direction
#       when Twilio::SMS_OUTBOUND_API
#         plan.calculate_outbound_sms_cost( self.provider_price )
#       when Twilio::SMS_INBOUND_API
#         plan.calculate_inbound_sms_cost( self.provider_price )
#     end
#   end
  
  def calculate_our_cost( value=nil )
    return nil unless self.conversation && self.conversation.stencil && self.conversation.stencil.organization && self.conversation.stencil.organization.account_plan
    value = self.provider_cost if value.nil?
    plan = self.conversation.stencil.organization.account_plan
    return case self.direction
      when DIRECTION_OUT
        plan.calculate_outbound_sms_cost( value )
      when DIRECTION_IN
        plan.calculate_inbound_sms_cost( value )
    end
  end
  
  def deliver!()
    begin
      #self.provider_response = self.conversation.stencil.organization.twilio_account.sms.messages.create({
      #  to: self.to_number,
      #  from: self.from_number,
      #  body: self.body,
      #  status_callback: self.conversation.stencil.organization.twilio_sms_status_url
      #}).to_property_hash
      
      self.provider_response = self.conversation.stencil.organization.send_sms( self.to_number, self.from_number, body, { default_callback: true, response_format: :smash })

      self.twilio_sid = self.provider_response.sms_sid
      self.status = Message.translate_twilio_message_status( self.provider_response.status )
      self.provider_cost = self.provider_response.price

    rescue Twilio::REST::RequestError => ex
      self.status = FAILED

      error_code = Conversation.translate_twilio_error_to_conversation_status ex.code
      if Conversation::CRITICAL_ERRORS.include? error_code
        raise SignalCloud::CriticalMessageSendingError.new( self.body, ex, error_code ) # Rethrow as a critical error
      else
        raise SignalCloud::MessageSendingError.new( self.body, ex, error_code ) # Rethrow in nice wrapper error
      end

    ensure
      self.save
    end
  end
  
  def self.translate_twilio_message_status( status )
    return case status
      when 'sent'; SENT
      when 'queued'; QUEUED
      when 'sending'; SENDING
      when 'received'; RECEIVED
      else; nil
    end
  end
  
#   def payload=(value)
#     super(value)
#     
#     # If a 'price' is set in the payload, update all costs
#     self.provider_cost = self.provider_price if self.has_provider_price?
#     self.our_cost = self.calculcate_our_cost( self.provider_cost )
#     
#     # If a ledger_entry is available, update it
#     if not self.ledger_entry.nil?
#       self.ledger_entry.value = self.cost
#     end
#   end
  
#   def callback_payload=(value)
#     super(value)
#     
#     # If a 'price' is set in the payload, update all costs
#     self.provider_cost = self.provider_price if self.has_provider_price?
#     self.our_cost = self.calculcate_our_cost( self.provider_cost )
#     
#     # If a ledger_entry is available, update it
#     if not self.ledger_entry.nil?
#       self.ledger_entry.value = self.cost
#     end
#   end
  
  def provider_cost=(value)
    super(value)
    self.our_cost = value.nil? ? nil : self.calculate_our_cost(value)
  end
  
  ##
  # Is a cost defined for this message?
  def has_cost?
    return !(self.our_cost.nil? or self.provider_cost.nil?)
  end
  
  ##
  # Cost of this message, combining provider and own charges
  def cost
    return (self.our_cost || 0) + (self.provider_cost || 0)
  end
  
  ##
  # Caches the payload, as frequent accesses to the encrypted, marshalled payload will slow down processing
#   def cached_payload
#     return ( @cached_payload ||= (self.callback_payload.nil? ? self.payload : self.callback_payload).try(:with_indifferent_access) )
#   end
  
  ##
  # Clear cached payload.
#   def clear_cached_payload
#     @cached_payload = nil
#   end
  
  ##
  # Shortcut to access the payload's 'body' parameter
  # def body(reload=false)
    # self.clear_cached_payload if reload
    # return self.cached_payload.fetch(:body, nil)
  # end
  
  ##
  # Shortcut to access the payload's 'to' parameter
  # def to_number(reload=false)
    # self.clear_cached_payload if reload
    # return self.cached_payload.fetch(:to, nil)
  # end
  
  ##
  # Shortcut to access the payload's 'from' parameter
  # def from_number(reload=false)
    # self.clear_cached_payload if reload
    # return self.cached_payload.fetch(:from, nil)
  # end

  ##
  # Shortcut to access the payload's 'direction' parameter
#   def direction(reload=false)
#     self.clear_cached_payload if reload
#     return self.cached_payload.fetch(:direction, nil)
#   end
  
  ##
  # Internal cost
#   def provider_price(reload=false)
#     self.clear_cached_payload if reload
#     return self.cached_payload.fetch(:price, nil)
#   end
  
#   alias :internal_provider_cost :provider_price
  
#   def has_provider_price?(reload=true)
#     #self.clear_cached_payload if reload
#     begin
#       price = self.payload.with_indifferent_access.fetch(:price, nil)
#       return !price.nil? && ( Float(price) != nil )
#     rescue
#       return false
#     end
#   end
  
  ##
  # Query the Twilio status of this message.
  def twilio_status
    self.conversation.stencil.organization.twilio_account.sms.messages.get( self.twilio_sid )
  end
  
  def refresh_from_twilio
    response = self.twilio_status
    self.status = Message.translate_twilio_message_status response.status
    self.sent_at = response.date_sent
    self.provider_cost = ( Float(response.price) rescue nil )
    self.provider_response = response.to_property_hash
  end
  
  def refresh_from_twilio!
    self.refresh_from_twilio
    self.save!
  end
  
  ##
  # Is this message a challenge?
  def is_challenge?
    self.message_kind == CHALLENGE
  end
  
  ##
  # Is this message a reply?
  def is_reply?
    self.message_kind == REPLY
  end
  
  def build_ledger_entry( attributes={} )
    ledger_entry = super(attributes)
    ledger_entry.organization = self.organization
    return ledger_entry
  end

end
