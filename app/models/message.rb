# encoding: UTF-8
class Message < ActiveRecord::Base
  include Workflow
  
  workflow do
    state :pending do
      event :deliver, transitions_to: :sending
      event :receive, transitions_to: :received
      event :error, transitions_to: :errored
    end
    state :sending do
      event :confirm, transitions_to: :sent
      event :fail, transitions_to: :failed
      event :error, transitions_to: :errored
    end
    state :sent
    state :failed
    state :received
    state :errored
  end
  
  before_validation :update_ledger_entry

  SMS_CHARSET_LIST = " @Δ0¡P¿p£_!1AQaq$Φ\"2BRbr¥Γ#3CScsèΛ¤4DTdtéΩ%5EUeuùΠ&6FVfvìΨ'7GWgwòΣ(8HXhxÇΘ)9IYiy\nΞ*:JZjzØ\e+;KÄkäøÆ,<LÖlö\ræ=MÑmñÅß.>NÜnüåÉ/?O§oà-"
  SMS_CHARSET = /\A[ @Δ0¡P¿p£_!1AQaq$Φ"2BRbr¥Γ#3CScsèΛ¤4DTdtéΩ%5EUeuùΠ&6FVfvìΨ'7GWgwòΣ\(8HXhxÇΘ\)9IYiy\nΞ*:JZjzØ\e+;KÄkäøÆ,<LÖlö\ræ=MÑmñÅß.>NÜnüåÉ\/?O§oà-]+\Z/
  SMS_CBS_MAX_LENGTH = 160
  SMS_UTF_MAX_LENGTH = 70
  
  CHALLENGE = 'challenge'
  REPLY = 'reply'
  RESPONSE = 'response'
  
  PENDING = 0
  QUEUED = 1
  SENDING = 2
  SENT = 3
  FAILED = 4
  RECEIVED = 5
  ERRORED = 6
  
  def self.status_to_code( status )
    case status
      when 'pending'; PENDING
      when 'sending'; SENDING
      when 'sent'; SENT
      when 'failed'; FAILED
      when 'received'; RECEIVED
      when 'errored'; ERRORED
    end
  end
  
  OPEN_STATUSES = [ 'pending', 'sending' ]
  # CLOSED_STATUSES = [ SENT, FAILED, RECEIVED ]
  # STATUSES = OPEN_STATUSES + CLOSED_STATUSES
  
  IN = 'in'
  OUT = 'out'

  ##
  # Encrypted payload. Serialised using JSON.
  attr_encrypted :provider_response, key: ATTR_ENCRYPTED_SECRET, marshal: true, marshaler: JSON

  ##
  # Encrypted callback payload. Serialised using JSON.
  attr_encrypted :provider_update, key: ATTR_ENCRYPTED_SECRET, marshal: true, marshaler: JSON

  ##
  # Encrypted customer phone number.
  attr_encrypted :to_number, key: ATTR_ENCRYPTED_SECRET
  
  ##
  # Encrypted internal phone number.
  attr_encrypted :from_number, key: ATTR_ENCRYPTED_SECRET
  
  ##
  # Encrypted body of message.
  attr_encrypted :body, key: ATTR_ENCRYPTED_SECRET

  ##
  # Parent conversation, of which this message is part of the conversation.
  belongs_to :conversation, inverse_of: :messages
  
  ##
  # Chain up to parent's organization.
  delegate :organization, :to => :conversation, :allow_nil => true
  
  ##
  # LedgerEntry for this message.
  has_one :ledger_entry, as: :item, autosave: true

  # Validations
  validates_presence_of :conversation
  validates_numericality_of :our_cost, allow_nil: true
  validates_numericality_of :provider_cost, allow_nil: true
  validates_length_of :provider_sid, is: Twilio::SID_LENGTH, allow_nil: true
  validates_uniqueness_of :provider_sid, allow_nil: true

  validates_inclusion_of :message_kind, in: [ CHALLENGE, REPLY, RESPONSE, :challenge, :reply, :response ]
  validates_inclusion_of :direction, in: [ IN, OUT, :in, :out ]
  
  scope :outstanding, ->{ where( 'messages.status in (?)', OPEN_STATUSES ) }
  
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
      when OUT; LedgerEntry::OUTBOUND_SMS_NARRATIVE
      when IN; LedgerEntry::INBOUND_SMS_NARRATIVE
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
    
    unless self.ledger_entry.nil?
      # Force an update of the ledger entry's organization
      self.ledger_entry.organization = self.organization
      
      # Finally, try to save the ledger entry if it exists and this is NOT a new record
      # self.ledger_entry.save unless self.new_record?
    end
  end
  
  def calculate_our_cost( value=nil )
    return 0 unless self.conversation && self.conversation.stencil && self.conversation.stencil.organization && self.conversation.stencil.organization.account_plan
    value = self.provider_cost if value.nil?
    plan = self.conversation.stencil.organization.account_plan
    return case self.direction
      when OUT
        plan.calculate_outbound_sms_cost( value )
      when IN
        plan.calculate_inbound_sms_cost( value )
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
  
  def provider_cost=(value)
    super(value)
    self.our_cost = value.nil? ? nil : self.calculate_our_cost(value)
    self.update_ledger_entry
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
  # Query the provider (Twilio, Nexmo, etc.) status of this message.
  def provider_status
    # self.organization.twilio_account.sms.messages.get( self.twilio_sid )
    self.conversation.communication_gateway.sms_status self.provider_id
  end
  
  ##
  # Query the provider (Twilio, Nexmo, etc.) status of this message.
  def refresh_from_provider
    response = self.provider_status.to_property_smash
    self.status = response.message_status # Message.translate_twilio_message_status response.status
    self.sent_at = response.sent_at
    self.provider_cost = response.price # ( Float(response.price) rescue nil )
    self.provider_response = response
  end
  
  def refresh_from_provider!
    self.refresh_from_provider
    self.save!
  end
  
  alias_method :twilio_status, :provider_status
  alias_method :refresh_from_twilio, :refresh_from_provider
  alias_method :refresh_from_twilio!, :refresh_from_provider!
  
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

protected

  def deliver
#     begin
    unless self.conversation.mock
      self.provider_response = self.conversation.communication_gateway.send_sms!( self.to_number, self.from_number, body, { default_callback: true, response_format: :smash })
      self.provider_sid = self.provider_response.sms_sid
      self.provider_cost = self.provider_response.price
    end

#     rescue Twilio::REST::RequestError => ex
#       self.status = FAILED
# 
#       error_code = Conversation.translate_twilio_error_to_conversation_status ex.code
#       if Conversation::CRITICAL_ERRORS.include? error_code
#         raise SignalCloud::CriticalMessageSendingError.new( self.body, ex, error_code ) # Rethrow as a critical error
#       else
#         raise SignalCloud::MessageSendingError.new( self.body, ex, error_code ) # Rethrow in nice wrapper error
#       end
# 
#     ensure
#       self.save
#     end
  end

  def receive( payload=nil )
    # Update self with information from payload
    self.provider_sid = payload.sms_sid
    self.refresh_from_provider
  end

  def confirm
    # Do nothing?
  end

  def fail
    # Do nothing?
  end
  
  def error
    # Do nothing?
  end

end
