# encoding: UTF-8
class Conversation < ActiveRecord::Base

  before_validation :update_expiry_time_based_on_seconds_to_live
  before_save :normalize_phone_numbers, :hash_phone_numbers

  # Status constants
  PENDING = 0
  QUEUED = 1
  CHALLENGE_SENT = 2
  CONFIRMED = 3
  DENIED = 4
  FAILED = 5
  EXPIRED = 6
  OPEN_STATUSES = [ PENDING, QUEUED, CHALLENGE_SENT ]
  STATUSES = [ PENDING, QUEUED, CHALLENGE_SENT, CONFIRMED, DENIED, FAILED, EXPIRED ]
  
  # SMS status constants
  # SENT = CHALLENGE_SENT
  
  # Error constants
  ERROR_INVALID_TO = 101
  ERROR_INVALID_FROM = 102
  ERROR_BLACKLISTED_TO = 105
  ERROR_NOT_SMS_CAPABLE = 103
  ERROR_CANNOT_ROUTE = 104
  ERROR_SMS_QUEUE_FULL = 106
  ERROR_INTERNATIONAL = 107
  ERROR_MISSING_BODY = 108
  ERROR_BODY_TOO_LARGE = 109
  ERROR_UNKNOWN = 127
  ERROR_STATUSES = [ ERROR_INVALID_TO, ERROR_INVALID_FROM, ERROR_BLACKLISTED_TO, ERROR_NOT_SMS_CAPABLE, ERROR_CANNOT_ROUTE, ERROR_SMS_QUEUE_FULL, ERROR_INTERNATIONAL, ERROR_MISSING_BODY, ERROR_BODY_TOO_LARGE, ERROR_UNKNOWN ]
  CRITICAL_ERRORS = [ ERROR_MISSING_BODY, ERROR_BODY_TOO_LARGE, ERROR_INTERNATIONAL ]

  attr_accessible :seconds_to_live, :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at, :webhook_uri
  attr_accessor :seconds_to_live
  
  # Encrypted attributes
  attr_encrypted :question,         key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :confirmed_reply,  key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply,     key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply,     key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply,    key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :expected_confirmed_answer,  key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer,     key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :to_number,        key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :from_number,      key: ATTR_ENCRYPTED_SECRET

  # Relationships
  belongs_to :stencil, inverse_of: :conversations
  has_many :messages, inverse_of: :conversation
  #has_many :ledger_entries, as: :item

  delegate :organization, :to => :stencil, :allow_nil => true
  
  # Validation
  validates_presence_of :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at
  validates :to_number, phone_number: true
  validates :from_number, phone_number: true
  validates_numericality_of :challenge_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  validates_numericality_of :reply_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  
  # Scopes
  scope :opened, where( :status => OPEN_STATUSES )
  scope :closed, where( 'status not in (?)', OPEN_STATUSES )
  scope :today, lambda{ where( "conversations.created_at >= ? and conversations.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  scope :yesterday, lambda{ where( "conversations.created_at >= ? and conversations.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :last_x_days, lambda{ where( "conversations.created_at >= ? and conversations.created_at <= ?", 7.days.ago.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :created_between, lambda{ |lower,upper| where( "conversations.created_at >= ? and conversations.created_at <= ?", lower.beginning_of_day, upper.end_of_day ) }
  scope :count_by_status, select('count(conversations.*) as count, conversations.status').group('conversations.status')
  scope :outstanding, where( 'challenge_sent_at is null or response_received_at is null or reply_sent_at is null' )
  
  ##
  # Standardise all messages for easier comparisons and matching.
  def self.normalize_message( msg )
    return msg.gsub(/[$£€¥]/, '').to_ascii.gsub(/[^[:alnum:]]/,'').downcase
  end
  
  ##
  # Provide a standardised way to convert a phone number into a deterministic hash.
  def self.hash_phone_number( phone_number )
    # BCrypt::Password.new( BCrypt::Engine.hash_secret( pn, ATTR_ENCRYPTED_SECRET, BCrypt::Engine::DEFAULT_COST ) )
    phone_number.nil? ? nil : Digest::SHA1.base64digest( ATTR_ENCRYPTED_SECRET + phone_number.to_s )
  end
  
  def self.find_open_conversations( internal_number, customer_number )
    #e_internal_number = Conversation.encrypt( :from_number, PhoneNumber.normalize_phone_number(internal_number) )
    #e_customer_number = Conversation.encrypt( :to_number, PhoneNumber.normalize_phone_number(customer_number) )
    #Conversation.where( encrypted_from_number: e_internal_number, encrypted_to_number: e_customer_number, status: Conversation::OPEN_STATUSES )
    Conversation.where(
      hashed_internal_number: Conversation.hash_phone_number( internal_number ),
      hashed_customer_number: Conversation.hash_phone_number( customer_number )
    ).opened
  end
  
  def self.count_by_status_hash( conversation_query )
    counts = conversation_query.count_by_status.readonly.each_with_object({}) { |v, h| h[v.status] = v.count.to_i }
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
    self.to_number = PhoneNumber.normalize_phone_number(self.to_number)
    self.from_number = PhoneNumber.normalize_phone_number(self.from_number)
  end
  
  ##
  # Standardise phone number hashes, to be used in searches for open conversations.
  def hash_phone_numbers
    self.hashed_internal_number = Conversation.hash_phone_number( self.from_number )
    self.hashed_customer_number = Conversation.hash_phone_number( self.to_number )
  end
  
  def status_text()
    Conversation.status_text( self.status )
  end
  
  def normalized_expected_confirmed_answer
    Conversation.normalize_message self.expected_confirmed_answer
  end
  
  def normalized_expected_denied_answer
    Conversation.normalize_message self.expected_denied_answer
  end
  
  def answer_applies?(answer)
    self.compare_answer( answer ) != Conversation::FAILED
  end
  
  def compare_answer( answer )
    return case Conversation.normalize_message(answer)
      when self.normalized_expected_confirmed_answer
        Conversation::CONFIRMED
      when self.normalized_expected_denied_answer
        Conversation::DENIED
      else
        Conversation::FAILED
    end
  end
  
  ##
  # Update this conversation with appropriate flags indicating that a response has been received.
  def accept_answer( answer, received=DateTime.now )
    self.status = self.compare_answer(answer)
    self.response_received_at = received
  end
  
  ##
  # Accept the given answer and force a database save.
  def accept_answer!( answer, received=DateTime.now )
    self.accept_answer( answer, received )
    self.save!
  end

  ##
  # Is the conversation currently open? Based upon the conversation's status.
  def is_open?
    return Conversation::OPEN_STATUSES.include? self.status
  end
  
  ##
  # Is the conversation currently closed? Based upon the conversation's status.
  def is_closed?
    return !self.is_open?
  end
  
  ##
  # Check if conversation is open and if the conversation's expires_at is in the past
  def is_expired?
    return self.expires_at <= DateTime.now
  end
  
  ##
  # Is the conversation currently in an error state? Based upon the conversation's status.
  def has_errored?
    return Conversation::ERROR_STATUSES.include? self.status
  end
  
  ##
  # Choose the appropriate message to send based upon the conversation's status.
  # If the conversation does not have a message ready, due to the conversation's status, raise a
  # +MessageAlreadySentError+.
  def select_reply_message_to_send()
    return case self.status
      when CONFIRMED
        self.confirmed_reply
      when DENIED
        self.denied_reply
      when FAILED
        self.failed_reply
      when EXPIRED
        self.expired_reply
      else
        raise SignalCloud::InvalidConversationStateError(self)
      end
  end
  
  def send_challenge_message( force_resend = false )

    # Abort if message already sent and we do not want to force a resend
    raise SignalCloud::ChallengeAlreadySentError.new(self) unless ( force_resend || !self.has_challenge_been_sent? )

    # Send the message, catching any errors
    begin
      sent_messages = self.send_message( self.question, Message::CHALLENGE, force_resend )
      self.status = QUEUED
      self.challenge_status = QUEUED
      return sent_messages

    rescue SignalCloud::MessageSendingError => ex
      # Set message status
      self.status = ex.code
      self.challenge_status = ex.code
      
      # Log as appropriate
      if ex.instance_of?( SignalCloud::CriticalMessageSendingError )
        logger.error 'Conversation %s encountered critical error while sending challenge message (code %s)!' % [ self.id, self.challenge_status ]
      else
        logger.info 'Conversation %s encountered error while sending challenge message (code %s).' % [ self.id, self.challenge_status ]
      end
      
      # Rethrow
      raise ex
    end
  end
  
  def send_challenge_message!( force_resend = false )
    begin
      self.send_challenge_message(force_resend)
    ensure
      self.save
    end
  end
  
  def send_reply_message( force_resend = false )

    # Abort if message already sent and we do not want to force a resend
    raise SignalCloud::ReplyAlreadySentError.new(self) unless ( force_resend || !self.has_reply_been_sent? )
    
    # Send the message, catching any errors
    begin
      sent_messages = self.send_message( self.select_reply_message_to_send, Message::REPLY, force_resend )
      self.reply_status = QUEUED
      return sent_messages

    rescue SignalCloud::MessageSendingError => ex
      # Set message status
      self.reply_status = ex.code
      
      # Log as appropriate
      if ex.instance_of?( SignalCloud::CriticalMessageSendingError )
        logger.error 'Conversation %s encountered critical error while sending reply message (code %s)!' % [ self.id, self.reply_status ]
      else
        logger.info 'Conversation %s encountered error while sending reply message (code %s)!' % [ self.id, self.reply_status ]
      end
      
      # Rethrow
      raise ex
    end
  end
  
  def send_reply_message!( force_resend = false )
    begin
      self.send_reply_message(force_resend)
    ensure
      self.save
    end
  end
  
  ##
  # Send challenge SMS message. This will construct the appropriate SMS 'envelope' and pass to the +Conversation's+ +Account+. This will also convert
  # the results into a message, to be held for reference.
  def send_message( message_body, message_kind = nil, force_resend = false )
    raise SignalCloud::CriticalMessageSendingError.new( nil, nil, Conversation::ERROR_MISSING_BODY ) if message_body.blank?
  
    # Do an initial clean-up on the body
    message_body.strip!
  
    begin
      chunking_strategy = Message.select_message_chunking_strategy( message_body )
      return message_body.scan( chunking_strategy ).map do |message_part|
        msg = self.messages.build( to_number: self.to_number, from_number: self.from_number, body: message_part, message_kind: message_kind, direction: Message::DIRECTION_OUT )
        msg.deliver!
        msg
        # Send the SMS
        #results = self.stencil.organization.send_sms( self.to_number, self.from_number, message_part )
  
        # Build a message and ledger_entry to hold the results
        # sent_message = self.messages.build( twilio_sid: results.sid, provider_response: results.to_property_hash )
        # ledger_entry = sent_message.build_ledger_entry( narrative: LedgerEntry::OUTBOUND_SMS_NARRATIVE )
        # sent_message
      end

    rescue Twilio::REST::RequestError => ex
      error_code = Conversation.translate_twilio_error_to_conversation_status ex.code
      if CRITICAL_ERRORS.include? error_code
        raise SignalCloud::CriticalMessageSendingError.new( message_body, ex, error_code ) # Rethrow as a critical error
      else
        raise SignalCloud::MessageSendingError.new( message_body, ex, error_code ) # Rethrow in nice wrapper error
      end
    end

  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_challenge_been_sent?
    return !self.challenge_sent_at.nil?
  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_response_been_received?
    return !self.response_received_at.nil?
  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_reply_been_sent?
    return !self.reply_sent_at.nil?
  end
  
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
  
  ##
  # Translate a given Twilio error message into a conversation status message
  def self.translate_twilio_error_to_conversation_status( error_code )
    return case error_code
      when Twilio::ERR_INVALID_TO_PHONE_NUMBER, Twilio::ERR_SMS_TO_REQUIRED
        ERROR_INVALID_TO
      when Twilio::ERR_INVALID_FROM_PHONE_NUMBER, Twilio::ERR_SMS_FROM_REQUIRED
        ERROR_INVALID_FROM
      when Twilio::ERR_FROM_PHONE_NUMBER_NOT_SMS_CAPABLE, Twilio::ERR_TO_PHONE_NUMBER_NOT_VALID_MOBILE
        ERROR_NOT_SMS_CAPABLE
      when Twilio::ERR_FROM_PHONE_NUMBER_EXCEEDED_QUEUE_SIZE
        ERROR_SMS_QUEUE_FULL
      when Twilio::ERR_TO_PHONE_NUMBER_CANNOT_RECEIVE_SMS
        ERROR_CANNOT_ROUTE
      when Twilio::ERR_TO_PHONE_NUMBER_IS_BLACKLISTED
        ERROR_BLACKLISTED_TO
      when Twilio::ERR_INTERNATIONAL_NOT_ENABLED
        ERROR_INTERNATIONAL
      when Twilio::ERR_SMS_BODY_REQUIRED
        ERROR_MISSING_BODY
      when Twilio::ERR_SMS_BODY_EXCEEDS_MAXIMUM_LENGTH
        ERROR_BODY_TOO_LARGE
      else
        ERROR_UNKNOWN
      end
  end

  def self.status_text( status_code=nil )
    case status_code
      when PENDING
        'Pending'
      when QUEUED
        'Queued'
      when CHALLENGE_SENT
        'Challenge sent - Waiting for reply'
      when CONFIRMED
        'Confirmed'
      when DENIED
        'Denied'
      when FAILED
        'Failed'
      when EXPIRED
        'Expired'
      when nil
        nil
      else
        "Error: #{status_code}"
    end
  end
  
end
