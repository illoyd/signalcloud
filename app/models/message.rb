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
  
  PENDING_SZ = 'pending'
  SENDING_SZ = 'sending'
  SENT_SZ    = 'sent'
  FAILED_SZ  = 'failed'
  RECEIVED_SZ = 'received'
  ERRORED_SZ = 'errored'
  
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
  delegate :organization, :communication_gateway, to: :conversation

  # Validations
  validates_presence_of :conversation
  validates_numericality_of :cost, allow_nil: true
  validates_numericality_of :segments, only_integer: true, greater_than_or_equal_to: 0

  validates_inclusion_of :message_kind, in: [ CHALLENGE, REPLY, RESPONSE, :challenge, :reply, :response ]
  validates_inclusion_of :direction, in: [ IN, OUT, :in, :out ]
  
  scope :outstanding, ->{ where( 'messages.workflow_state in (?)', OPEN_STATUSES ) }
  scope :challenges,  ->{ where( message_kind: CHALLENGE ) }
  scope :responses,   ->{ where( message_kind: RESPONSE ) }
  scope :replies,     ->{ where( message_kind: REPLY ) }
  scope :inbound,     ->{ where( direction: IN ) }
  scope :outbound,    ->{ where( direction: OUT ) }

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
  
  def self.translate_twilio_message_status( status )
    return case status
      when 'sent'; SENT
      when 'queued'; QUEUED
      when 'sending'; SENDING
      when 'received'; RECEIVED
      else; nil
    end
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
    self.cost = response.price
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
  
protected

  def deliver
    begin
      unless self.conversation.mock
        self.provider_response = self.communication_gateway.send_sms!( self.to_number, self.from_number, body, { default_callback: true, response_format: :smash })
        logger.info "Transmitted message. #{self.provider_response}."
        self.provider_sid = self.provider_response.sid
        self.cost = self.provider_response.price
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
