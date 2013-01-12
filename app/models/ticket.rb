# encoding: UTF-8
class Ticket < ActiveRecord::Base

  before_validation :update_expiry_time_based_on_seconds_to_live
  before_save :normalize_phone_numbers

  # Constants
  PENDING = 0
  QUEUED = 1
  CHALLENGE_SENT = 2
  CONFIRMED = 3
  DENIED = 4
  FAILED = 5
  EXPIRED = 6
  OPEN_STATUSES = [ QUEUED, CHALLENGE_SENT ]
  
  ERROR_INVALID_TO = 101
  ERROR_INVALID_FROM = 102
  ERROR_BLACKLISTED_TO = 105
  ERROR_NOT_SMS_CAPABLE = 103
  ERROR_CANNOT_ROUTE = 104
  ERROR_SMS_QUEUE_FULL = 106
  ERROR_INTERNATIONAL = 107
  ERROR_UNKNOWN = 127
  ERROR_STATUSES = [ ERROR_INVALID_TO, ERROR_INVALID_FROM, ERROR_BLACKLISTED_TO, ERROR_NOT_SMS_CAPABLE, ERROR_CANNOT_ROUTE, ERROR_SMS_QUEUE_FULL, ERROR_INTERNATIONAL, ERROR_UNKNOWN ]

  attr_accessible :seconds_to_live, :appliance_id, :actual_answer, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry
  attr_accessor :seconds_to_live
  
  # Encrypted attributes
  attr_encrypted :actual_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :from_number, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :to_number, key: ATTR_ENCRYPTED_SECRET
  
  # Relationships
  belongs_to :appliance, inverse_of: :tickets
  has_many :messages, inverse_of: :ticket
  has_many :transactions, as: :item
  
  # Validation
  validates_presence_of :appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry
  validates :to_number, phone_number: true
  validates :from_number, phone_number: true
  #validates_numericality_of :seconds_to_live
  validates_numericality_of :challenge_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  validates_numericality_of :reply_status, allow_nil: true, integer_only: true, greater_than_or_equal_to: 0
  
  # Scopes
  scope :opened, where( :status => [ QUEUED, CHALLENGE_SENT ] )
  scope :closed, where( 'status not in (?)', [ QUEUED, CHALLENGE_SENT ] )
  scope :today, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day )
  scope :yesterday, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day )
  
  def self.normalize_message( msg )
    return msg.gsub(/[$£€¥]/, '').to_ascii.gsub(/[^[:alnum:]]/,'').downcase
  end

  ##
  # Update expiry based upon seconds to live
  def update_expiry_time_based_on_seconds_to_live
    unless self.seconds_to_live.nil?
      ss = ( Float(self.seconds_to_live) rescue nil )
      self.expiry = ss.seconds.from_now unless ss.nil?
    end
  end
  
  ##
  # Normalize phone numbers using the Phony library.
  def normalize_phone_numbers
    self.to_number = '+' + Phony.normalize(self.to_number)
    self.from_number = '+' + Phony.normalize(self.from_number)
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
  # Is the ticket currently in an error state? Based upon the ticket's status.
  def has_errored?
    return Ticket::ERROR_STATUSES.include? self.status
  end
  
  def send_message( message, force_resend = false )
  end
  
  ##
  # Choose the appropriate message to send based upon the ticket's status.
  # If the ticket does not have a message ready, due to the ticket's status, raise a
  # +MessageAlreadySentError+.
  def select_next_message_to_send()
    return case self.status
      when PENDING, QUEUED, CHALLENGE_SENT
        self.question
      when CONFIRMED
        self.confirmed_reply
      when DENIED
        self.denied_reply
      when FAILED
        self.failed_reply
      when EXPIRED
        self.expired_reply
      else
        raise InvalidTicketStateError()
      end
  end
  
  def should_send_next_message?()
    return case self.status
      when PENDING, QUEUED
        !self.has_challenge_been_sent?
      when CONFIRMED, DENIED, FAILED, EXPIRED
        !self.has_reply_been_sent?
      else
        false
      end
  end
  
  def send_challenge_message( force_resend = false )

    # Abort if message already sent and we do not want to force a resend
    raise Ticketplease::ChallengeAlreadySentError unless ( force_resend || !self.has_challenge_been_sent? )
    
    # Send the message, catching any errors
    begin
      return self.send_message( self.question, force_resend )
      self.challenge_status = QUEUED

    rescue Ticketplease::MessageSendingError => ex
      # Set message status
      self.challenge_status = ex.code
      raise ex

    ensure
      # Always save self
      self.save!
    end

  end
  
  def send_reply_message( force_resend = false )

    # Abort if message already sent and we do not want to force a resend
    raise Ticketplease::ReplyAlreadySentError unless ( force_resend || !self.has_reply_been_sent? )
    
    # Send the message, catching any errors
    begin
      return self.send_message( self.select_reply_message_to_send, force_resend )
      self.reply_status = QUEUED

    rescue Ticketplease::MessageSendingError => ex
      # Set message status
      self.reply_status = ex.code
      raise ex

    ensure
      # Always save self
      self.save!
    end

  end
  
  ##
  # Send challenge SMS message. This will construct the appropriate SMS 'envelope' and pass to the +Ticket's+ +Account+. This will also convert
  # the results into a message, to be held for reference.
  def send_message( message_body, force_resend = false )
  
    # Otherwise, continue to send SMS and store the results
    message = nil
    #message_to = '+%s' % self.to_number
    #message_from = '+%s' % self.from_number
    begin
      # Send the SMS
      results = self.appliance.account.send_sms( self.to_number, self.from_number, message_body )

      # Build a message and transaction to hold the results
      message = self.messages.build( twilio_sid: results.sid, payload: results.to_property_hash )
      transaction = message.build_transaction( account: self.appliance.account, narrative: 'Outbound SMS' )
      
      # Update the ticket's status (includes both the main status as well as the challenge/reply )

    rescue Twilio::REST::RequestError => ex
      self.status = Ticket.translate_twilio_error_to_ticket_status ex.code
      case self.status
        when ERROR_INTERNATIONAL, ERROR_UNKNOWN
          raise Ticketplease::CriticalMessageSendingError.new( message, ex, self.status ) # Rethrow as a critical error
        else
          raise Ticketplease::MessageSendingError.new( message, ex, self.status ) # Rethrow in nice wrapper error
      end

    end

    # Return the completed message
    return message

  end
  
  ##
  # Send reply SMS message, based upon the +Ticket's+ current state. This will construct the appropriate SMS 'envelope' and pass to the +Ticket's+ +Account+.
  def send_reply_message( force_resend = false )
  
    # Abort if message already sent and we do not want to force a resend
    return if self.has_reply_been_sent? and !force_resend
    
    # Otherwise, continue to send SMS and store the results
    reply_body = case self.status
      when CONFIRMED
        self.confirmed_reply
      when DENIED
        self.denied_reply
      when FAILED
        self.failed_reply
      when EXPIRED
        self.expired_reply
    end
    
    # Send message via account
    self.appliance.account.send_sms( self.to_number, self.from_number, reply_body )
    
    # Construct the message and the related pending transaction object
    message = self.messages.create( twilio_sid: results.sid, payload: results.to_property_hash )
    transaction = message.build_transaction( account: self.appliance.account, narrative: Transaction::OUTBOUND_SMS_NARRATIVE )
    return message
  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_challenge_been_sent?
    return !self.challenge_sent.nil?
  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_response_been_received?
    return !self.response_received.nil?
  end
  
  ##
  # Has the challenge message already been sent to the recipient?
  def has_reply_been_sent?
    return !self.reply_sent.nil?
  end
  
  ##
  # Translate a given Twilio error message into a ticket status message
  def self.translate_twilio_error_to_ticket_status( error_code )
    return case error_code
      when Twilio::ERR_INVALID_TO_PHONE_NUMBER
        ERROR_INVALID_TO
      when Twilio::ERR_INVALID_FROM_PHONE_NUMBER
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
      else
        ERROR_UNKNOWN
      end
  end

end
