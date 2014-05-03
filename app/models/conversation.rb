# encoding: UTF-8
class Conversation < ActiveRecord::Base
  include Workflow

  workflow do
    state :draft do
      event :ask, transitions_to: :asking
      event :error, transitions_to: :errored
    end

    state :asking do
      event :asked, transitions_to: :asked
      event :expire, transitions_to: :expiring
      event :error, transitions_to: :errored
    end
    state :asked do
      event :receive, transitions_to: :receiving
      event :expire, transitions_to: :expiring
      event :error, transitions_to: :errored
    end

    state :receiving do
      event :received, transitions_to: :received
      event :error, transitions_to: :errored
    end
    state :received do
      event :confirm, transitions_to: :confirming
      event :deny, transitions_to: :denying
      event :fail, transitions_to: :failing
      event :error, transitions_to: :errored
    end

    state :confirming do
      event :confirmed, transitions_to: :confirmed
      event :error, transitions_to: :errored
    end
    state :denying do
      event :denied, transitions_to: :denied
      event :error, transitions_to: :errored
    end
    state :failing do
      event :failed, transitions_to: :failed
      event :error, transitions_to: :errored
    end
    state :expiring do
      event :expired, transitions_to: :expired
      event :error, transitions_to: :errored
    end

    state :confirmed
    state :denied
    state :failed
    state :expired
    state :errored
  end

  before_validation :update_expiry_time_based_on_seconds_to_live
  before_save :normalize_phone_numbers, :hash_phone_numbers, :update_ledger_entry

  # Status constants
  PENDING = 0
  QUEUED = 1
  CHALLENGE_SENT = 2
  CONFIRMED = 3
  DENIED = 4
  FAILED = 5
  EXPIRED = 6
  OPEN_STATUSES = [ :asking, :asked, 'asking', 'asked' ]
  STATUSES = [ PENDING, QUEUED, CHALLENGE_SENT, CONFIRMED, DENIED, FAILED, EXPIRED ]
  
  attr_accessor :seconds_to_live
  
  # Encrypted attributes
  attr_encrypted :question,         key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :confirmed_reply,  key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply,     key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply,     key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply,    key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :webhook_uri,      key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :expected_confirmed_answer,  key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer,     key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :customer_number,  key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :internal_number,  key: ATTR_ENCRYPTED_SECRET

  # Relationships
  belongs_to :stencil, inverse_of: :conversations
  belongs_to :box, inverse_of: :conversations
  has_many :messages, inverse_of: :conversation, autosave: true
  
  ##
  # LedgerEntry for this conversation.
  has_one :ledger_entry, as: :item, autosave: true

  delegate :organization, to: :stencil
  #delegate :communication_gateway, to: :internal_number, allow_nil: true
  
  def communication_gateway
    self.organization.phone_numbers.where( number: self.internal_number ).first.communication_gateway
  end
  
  # Before validation  
  before_validation :assign_internal_number #, on: :create
  
  # Validation
  validates_presence_of :stencil, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :expires_at
  validates :customer_number, phone_number: true
  validates :internal_number, phone_number: true
  validates_inclusion_of :challenge_status, in: Message.workflow_spec.valid_state_names, allow_nil: true
  validates_inclusion_of :reply_status, in: Message.workflow_spec.valid_state_names, allow_nil: true

  # Scopes
  scope :opened, ->{ where( :workflow_state => OPEN_STATUSES ) }
  scope :closed, ->{ where( 'workflow_state not in (?)', OPEN_STATUSES ) }
  scope :today, ->{ where( "conversations.created_at >= ? and conversations.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  scope :yesterday, ->{ where( "conversations.created_at >= ? and conversations.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :last_x_days, ->{ where( "conversations.created_at >= ? and conversations.created_at <= ?", 7.days.ago.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :created_between, ->(lower,upper){ where( "conversations.created_at >= ? and conversations.created_at <= ?", lower.beginning_of_day, upper.end_of_day ) }
  scope :count_by_status, ->{ select('count(conversations.*) as count, conversations.workflow_state').group('conversations.workflow_state') }
  scope :outstanding, ->{ where( 'challenge_sent_at is null or response_received_at is null or reply_sent_at is null' ) }
  
  ##
  # Standardise all messages for easier comparisons and matching.
  def self.normalize_message( msg )
    return msg.gsub(/[$£€¥]/, '').to_ascii.gsub(/[^[:alnum:]]/,'').downcase
  end
  
  ##
  # Provide a standardised way to convert a phone number into a deterministic hash.
  def self.hash_phone_number( phone_number )
    # BCrypt::Password.new( BCrypt::Engine.hash_secret( pn, ATTR_ENCRYPTED_SECRET, BCrypt::Engine::DEFAULT_COST ) )
    phone_number = PhoneNumber.normalize_phone_number(phone_number)
    phone_number.nil? ? nil : Digest::SHA1.base64digest( ATTR_ENCRYPTED_SECRET + phone_number )
  end
  
  def self.find_open_conversations( internal_number, customer_number )
    Conversation.where(
      hashed_internal_number: Conversation.hash_phone_number( internal_number ),
      hashed_customer_number: Conversation.hash_phone_number( customer_number )
    ).opened
  end
  
  def self.count_by_status_hash( conversation_query )
    counts = conversation_query.count_by_status.readonly.each_with_object({}) { |v, h| h[v.workflow_state] = v.count.to_i }
    Conversation::STATUSES.each { |status| counts[status] = 0 unless counts.include?(status) }
    return counts
  end

  ##
  # Update expires_at based upon seconds to live. Intended to be used with +before_save+ callbacks.
  def update_expiry_time_based_on_seconds_to_live
    unless self.seconds_to_live.nil?
      ss = ( Float(self.seconds_to_live) rescue nil )
      self.expires_at = ss.seconds.from_now unless ss.nil?
    end
  end
  
  ##
  # Normalize phone numbers. Intended to be used with +before_save+ callbacks.
  def normalize_phone_numbers
    self.customer_number = PhoneNumber.normalize_phone_number(self.customer_number)
    self.internal_number = PhoneNumber.normalize_phone_number(self.internal_number)
  end
  
  ##
  # Standardise phone number hashes, to be used in searches for open conversations.
  def hash_phone_numbers
    self.hashed_customer_number = Conversation.hash_phone_number( PhoneNumber.normalize_phone_number(self.customer_number) )
    self.hashed_internal_number = Conversation.hash_phone_number( PhoneNumber.normalize_phone_number(self.internal_number) )
  end
  
  def normalized_expected_confirmed_answer
    Conversation.normalize_message self.expected_confirmed_answer
  end
  
  def normalized_expected_denied_answer
    Conversation.normalize_message self.expected_denied_answer
  end
  
  def answer_applies?(answer)
    self.compare_answer( answer ) != :failed
  end
  
  def compare_answer( answer )
    return case Conversation.normalize_message(answer)
      when self.normalized_expected_confirmed_answer
        :confirmed
      when self.normalized_expected_denied_answer
        :denied
      else
        :failed
    end
  end
  
  ##
  # Update this conversation with appropriate flags indicating that a response has been received.
  def accept_answer!( answer, received=DateTime.now )
    case self.compare_answer(answer)
      when :confirmed 
        self.confirm!
      when :denied
        self.deny!
      else
        self.fail!
    end
  end
  
  ##
  # Is the conversation currently open? Based upon the conversation's status.
  def is_open?
    return ( asked? || asking? )
  end
  
  ##
  # Is the conversation currently closed? Based upon the conversation's status.
  def is_closed?
    return !self.is_open?
  end
  
  ##
  # Check if conversation is open and if the conversation's expires_at is in the past
  def is_expired?
    return self.expires_at <= Time.now
  end
  
  ##
  # Is the conversation currently in an error state? Based upon the conversation's status.
#   def has_errored?
#     return Conversation::ERROR_STATUSES.include? self.workflow_state
#   end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def challenge_sent?
    return !self.challenge_sent_at.nil?
  end
  alias_method :has_challenge_been_sent?, :challenge_sent?
  
  ##
  # Has the challenge message already been sent to the recipient?
  def response_received?
    return !self.response_received_at.nil?
  end
  alias_method :has_response_been_received?, :response_received?
  
  ##
  # Has the challenge message already been sent to the recipient?
  def reply_sent?
    return !self.reply_sent_at.nil?
  end
  alias_method :has_reply_been_sent?, :reply_sent?
  
  def has_outstanding_challenge_messages?
    return self.messages.where( 'message_kind = ? and status != ?', Message::CHALLENGE, Message::SENT ).any?
  end
  
  def has_outstanding_reply_messages?
    return self.messages.where( 'message_kind = ? and status != ?', Message::REPLY, Message::SENT ).any?
  end
  
  def settle_messages_statuses

    unless self.has_challenge_been_sent? or self.has_outstanding_challenge_messages?
      self.challenge_sent_at = self.messages.where( message_kind: Message::CHALLENGE ).maximum( :sent_at )
    end
    
    unless self.has_response_been_received?
      self.response_received_at = self.messages.where( 'status = ? or direction = ?', Message::RECEIVED, Message::DIRECTION_IN ).maximum( :sent_at )
    end

    unless self.has_reply_been_sent? or self.has_outstanding_reply_messages?
      self.reply_sent_at = self.messages.where( message_kind: Message::REPLY ).maximum( :sent_at )
    end

  end
  
  def settle_messages_statuses!
    self.settle_messages_statuses
    self.save!
  end
  
  def send_webhook_update
    # If no webhook specified, fail
    raise WebhookMissingError if self.webhook_uri.blank?
    
    # Assemble a webhook client and send self as update
    client = WebhookClient.new self.webhook_uri
    
    # Compile JSON and deliver it
    client.deliver self
    true    
  end

protected
  
  def assign_internal_number
    # Add a randomly selected from number if needed
    if self.internal_number.blank? and !self.customer_number.blank?
      self.internal_number = self.stencil.phone_book.select_internal_number_for( self.customer_number ).number
    end
  end

  def deliver_message( message_body, message_kind )
    msg = self.messages.create!( to_number: self.customer_number, from_number: self.internal_number, body: message_body, message_kind: message_kind, direction: :out )
    msg.deliver!
    msg
  end
  
  def update_ledger_entry
    if self.ledger_entry.nil?
      country = PhoneTools.country( self.customer_number )
      self.build_ledger_entry( organization: self.organization, narrative: "#{country.to_s.upcase} Conversation" )
    end
    self.ledger_entry.value = -self.organization.account_plan.price_for(self)
  end
  
protected

  def ask
    # Begin the process!
    self.deliver_message self.question, :challenge
  end

  def asked
    self.challenge_sent_at ||= Time.now
  end

  def confirm
    # Send confirmed reply
    self.deliver_message self.confirmed_reply, :reply

    # Send confirmed webhook
    self.send_webhook_update unless self.webhook_uri.blank?
  end
  
  def confirmed
    self.reply_sent_at ||= Time.now
  end
  
  def deny
    # Send denied reply
    self.deliver_message self.denied_reply, :reply

    # Send denied webhook
    self.send_webhook_update unless self.webhook_uri.blank?
  end
  
  def denied
    self.reply_sent_at ||= Time.now
  end
  
  def fail
    # Send failed reply
    self.deliver_message self.failed_reply, :reply
    self.reply_sent_at = Time.now

    # Send failed webhook
    self.send_webhook_update unless self.webhook_uri.blank?
  end
  
  def failed
    self.reply_sent_at ||= Time.now
  end

  def expire
    # Send expired reply
    self.deliver_message self.expired_reply, :reply
    self.reply_sent_at ||= Time.now

    # Send expired webhook
    self.send_webhook_update unless self.webhook_uri.blank?
  end
  
  def expired
    self.reply_sent_at ||= Time.now
  end
  
  def error
    # Send error webhook
    self.send_webhook_update unless self.webhook_uri.blank?
  end

end
