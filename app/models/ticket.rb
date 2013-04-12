# encoding: UTF-8
class Ticket < ActiveRecord::Base

  before_validation :update_expiry_time_based_on_seconds_to_live
  before_save :normalize_phone_numbers

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

  attr_accessible :seconds_to_live, :appliance_id, :actual_answer, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry, :webhook_uri
  attr_accessor :seconds_to_live
  
  # Encrypted attributes
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :from_number, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :to_number, key: ATTR_ENCRYPTED_SECRET
  # attr_encrypted :actual_answer, key: ATTR_ENCRYPTED_SECRET  
  
  # attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  # attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET

  # Relationships
  belongs_to :appliance, inverse_of: :tickets
  has_many :messages, inverse_of: :ticket
  #has_many :ledger_entries, as: :item

  delegate :account, :to => :appliance, :allow_nil => true
  
  # Validation
  validates_presence_of :appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry
  validates :to_number, phone_number: true
  validates :from_number, phone_number: true
  #validates_numericality_of :seconds_to_live
  validates_numericality_of :challenge_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  validates_numericality_of :reply_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  
  # Scopes
  scope :opened, where( :status => OPEN_STATUSES )
  scope :closed, where( 'status not in (?)', OPEN_STATUSES )
  scope :today, lambda{ where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  scope :yesterday, lambda{ where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :last_x_days, lambda{ where( "tickets.created_at >= ? and tickets.created_at <= ?", 7.days.ago.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :created_between, lambda{ |lower,upper| where( "tickets.created_at >= ? and tickets.created_at <= ?", lower.beginning_of_day, upper.end_of_day ) }
  scope :count_by_status, select('count(tickets.*) as count, tickets.status').group('tickets.status')
  scope :outstanding, where( 'challenge_sent_at is null or response_received_at is null or reply_sent_at is null' )
  
  ##
  # Standardise all messages for easier comparisons and matching.
  def self.normalize_message( msg )
    return msg.gsub(/[$£€¥]/, '').to_ascii.gsub(/[^[:alnum:]]/,'').downcase
  end
  
  def self.find_open_tickets( internal_number, customer_number )
    e_internal_number = Ticket.encrypt( :from_number, PhoneNumber.normalize_phone_number(internal_number) )
    e_customer_number = Ticket.encrypt( :to_number, PhoneNumber.normalize_phone_number(customer_number) )
    Ticket.where( encrypted_from_number: e_internal_number, encrypted_to_number: e_customer_number, status: Ticket::OPEN_STATUSES )
  end
  
  def self.count_by_status_hash( ticket_query )
    counts = ticket_query.count_by_status.readonly.each_with_object({}) { |v, h| h[v.status] = v.count.to_i }
    Ticket::STATUSES.each { |status| counts[status] = 0 unless counts.include?(status) }
    return counts
  end

  def expected_confirmed_answer
    @expected_confirmed_answer ||= BCrypt::Password.new(self.hashed_expected_confirmed_answer)
  end

  def expected_confirmed_answer=(new_value)
    @expected_confirmed_answer = BCrypt::Password.create(new_value)
    self.hashed_expected_confirmed_answer = @expected_confirmed_answer
  end
  
  def expected_denied_answer
    @expected_denied_answer ||= BCrypt::Password.new(self.hashed_expected_denied_answer)
  end

  def expected_denied_answer=(new_value)
    @expected_denied_answer = BCrypt::Password.create(new_value)
    self.hashed_expected_denied_answer = @expected_denied_answer
  end

  ##
  # Update expiry based upon seconds to live. Intended to be used with +before_save+ callbacks.
  def update_expiry_time_based_on_seconds_to_live
    unless self.seconds_to_live.nil?
      ss = ( Float(self.seconds_to_live) rescue nil )
      self.expiry = ss.seconds.from_now unless ss.nil?
    end
  end
  
  ##
  # Normalize phone numbers. Intended to be used with +before_save+ callbacks.
  def normalize_phone_numbers
    self.to_number = PhoneNumber.normalize_phone_number(self.to_number)
    self.from_number = PhoneNumber.normalize_phone_number(self.from_number)
  end
  
  def to_webhook_data
    data = [ :id, :appliance_id, :status, :status_text, :created_at, :updated_at, :challenge_sent_at, :challenge_status, :response_received_at, :reply_sent_at, :reply_status ].each_with_object({}) do |key,h|
      value = self.send key
      h[key] = value unless value.blank?
    end
    
    data[:open] = self.is_open? ? 1 : 0
    data[:closed] = self.is_closed? ? 1 : 0
    
    return data
  end
  
  def status_text
    case self.status
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
    end
  end
  
  def normalized_expected_confirmed_answer
    Ticket.normalize_message self.expected_confirmed_answer
  end
  
  def normalized_expected_denied_answer
    Ticket.normalize_message self.expected_denied_answer
  end
  
  def answer_applies?(answer)
    self.compare_answer( answer ) != Ticket::FAILED
  end
  
  def compare_answer( answer )
    return case Ticket.normalize_message(answer)
      when self.normalized_expected_confirmed_answer
        Ticket::CONFIRMED
      when self.normalized_expected_denied_answer
        Ticket::DENIED
      else
        Ticket::FAILED
    end
  end
  
  ##
  # 
  def accept_answer!( answer, received=DateTime.now )
    self.status = self.compare_answer(answer)
    self.response_received_at = received
    self.save!
  end

  ##
  # Is the ticket currently open? Based upon the ticket's status.
  def is_open?
    return Ticket::OPEN_STATUSES.include? self.status
  end
  
  ##
  # Is the ticket currently closed? Based upon the ticket's status.
  def is_closed?
    return !self.is_open?
  end
  
  ##
  # Check if ticket is open and if the ticket's expiry is in the past
  def is_expired?
    return self.expiry <= DateTime.now
  end
  
  ##
  # Is the ticket currently in an error state? Based upon the ticket's status.
  def has_errored?
    return Ticket::ERROR_STATUSES.include? self.status
  end
  
  ##
  # Choose the appropriate message to send based upon the ticket's status.
  # If the ticket does not have a message ready, due to the ticket's status, raise a
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
        raise SignalCloud::InvalidTicketStateError(self)
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
        logger.error 'Ticket %s encountered critical error while sending challenge message (code %s)!' % [ self.id, self.challenge_status ]
      else
        logger.info 'Ticket %s encountered error while sending challenge message (code %s).' % [ self.id, self.challenge_status ]
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
        logger.error 'Ticket %s encountered critical error while sending reply message (code %s)!' % [ self.id, self.reply_status ]
      else
        logger.info 'Ticket %s encountered error while sending reply message (code %s)!' % [ self.id, self.reply_status ]
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
  # Send challenge SMS message. This will construct the appropriate SMS 'envelope' and pass to the +Ticket's+ +Account+. This will also convert
  # the results into a message, to be held for reference.
  def send_message( message_body, message_kind = nil, force_resend = false )
    raise SignalCloud::CriticalMessageSendingError.new( nil, nil, Ticket::ERROR_MISSING_BODY ) if message_body.blank?
  
    # Do an initial clean-up on the body
    message_body.strip!
  
    begin
      chunking_strategy = Message.select_message_chunking_strategy( message_body )
      return message_body.scan( chunking_strategy ).map do |message_part|
        msg = self.messages.build( to_number: self.to_number, from_number: self.from_number, body: message_part, message_kind: message_kind, direction: Message::DIRECTION_OUT )
        msg.deliver!
        msg
        # Send the SMS
        #results = self.appliance.account.send_sms( self.to_number, self.from_number, message_part )
  
        # Build a message and ledger_entry to hold the results
        # sent_message = self.messages.build( twilio_sid: results.sid, provider_response: results.to_property_hash )
        # ledger_entry = sent_message.build_ledger_entry( narrative: LedgerEntry::OUTBOUND_SMS_NARRATIVE )
        # sent_message
      end

    rescue Twilio::REST::RequestError => ex
      error_code = Ticket.translate_twilio_error_to_ticket_status ex.code
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
  # Translate a given Twilio error message into a ticket status message
  def self.translate_twilio_error_to_ticket_status( error_code )
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

end
