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
    
    after_transition do |from, to, event, args|
      update_parent_status
      update_costs
    end
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
  
  OPEN_STATUSES = [ 'pending', 'sending', :pending, :sending ]
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
  validates_numericality_of :segments, only_integer: true, greater_than_or_equal_to: 0
  validates_length_of :provider_sid, is: Twilio::SID_LENGTH, allow_nil: true
  validates_uniqueness_of :provider_sid, allow_nil: true

  validates_inclusion_of :message_kind, in: [ CHALLENGE, REPLY, RESPONSE, :challenge, :reply, :response ]
  validates_inclusion_of :direction, in: [ IN, OUT, :in, :out ]
  
  scope :outstanding, ->{ where( 'messages.workflow_state in (?)', OPEN_STATUSES ) }
  scope :challenges,  ->{ where( message_kind: CHALLENGE ) }
  scope :responses,   ->{ where( message_kind: RESPONSE ) }
  scope :replies,     ->{ where( message_kind: REPLY ) }
  scope :inbound,     ->{ where( direction: IN ) }
  scope :outbound,    ->{ where( direction: OUT ) }
  
  ##
  # Delegate specific functions to the parent conversation
  delegate :communication_gateway, to: :conversation
  
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
      else; LedgerEntry::UNKNOWN_NARRATIVE
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
    self.conversation.communication_gateway.message(self.provider_sid).to_property_smash
  end
  
  ##
  # Query the provider (Twilio, Nexmo, etc.) status of this message.
  def refresh_from_provider
    response = self.provider_status
    self.sent_at = response.sent_at
    self.provider_cost = response.price
    self.provider_response = response
    
    # If provider says we've sent, send!
    self.confirm! if ( response.sent? and self.can_confirm? )
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
  def challenge?
    self.message_kind.to_s == CHALLENGE
  end
  alias_method :is_challenge?, :challenge?
  
  ##
  # Is this message a reply?
  def reply?
    self.message_kind.to_s == REPLY
  end
  alias_method :is_reply?, :reply?
  
  def build_ledger_entry( attributes={} )
    ledger_entry = super(attributes)
    ledger_entry.organization = self.organization
    return ledger_entry
  end
  
protected

  def deliver
    begin
      unless self.conversation.mock
        self.provider_response = self.communication_gateway.send_sms!( self.to_number, self.from_number, body, { default_callback: true, response_format: :smash })
        logger.info "Transmitted message. #{self.provider_response}."
        self.provider_sid = self.provider_response.sid
        self.provider_cost = self.provider_response.price
      end

    rescue SignalCloud::InvalidToNumberCommunicationGatewayError => ex
      raise SignalCloud::InvalidToNumberMessageSendingError.new self

    rescue SignalCloud::InvalidFromNumberCommunicationGatewayError => ex
      raise SignalCloud::InvalidFromNumberMessageSendingError.new self

    rescue SignalCloud::InvalidMessageBodyCommunicationGatewayError => ex
      raise SignalCloud::InvalidBodyMessageSendingError.new self

    rescue SignalCloud::CommunicationGatewayError => ex
      raise SignalCloud::CriticalMessageError.new self

    end
  end

  def receive( sid=nil )
    # Update self with information from payload
    self.provider_sid = sid unless sid.blank?
    self.refresh_from_provider unless self.provider_sid.blank?
    
    # Update parent conversation
    unless self.conversation.nil?
      self.conversation.response_received_at = self.sent_at
      # self.conversation.answer_status = self.workflow_state.to_s
    end
  end

  def confirm( time=nil )
    # Update sent_at time if needed
    self.sent_at ||= ( time || Time.now )

    # Update parent conversation
    unless self.conversation.nil?
      if self.challenge?
        self.conversation.challenge_sent_at ||= self.sent_at
      elsif self.reply?
        self.conversation.reply_sent_at ||= self.sent_at
      end
    end
  end

  def fail( time=nil )
    # Update sent_at time if needed
    self.sent_at ||= ( time || Time.now )

    # Update parent conversation
    unless self.conversation.nil?
      if self.challenge?
        self.conversation.challenge_sent_at ||= self.sent_at
      elsif self.reply?
        self.conversation.reply_sent_at ||= self.sent_at
      end
    end
  end
  
  def error
    # Do nothing
  end
  
  def update_parent_status
    unless self.conversation.nil?
      if self.challenge?
        self.conversation.challenge_status = self.workflow_state.to_s
      elsif self.reply?
        self.conversation.reply_status = self.workflow_state.to_s
      end
    end
  end
  
  def update_costs
    
  end
  
end
