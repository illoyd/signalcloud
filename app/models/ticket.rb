class Ticket < ActiveRecord::Base

  before_validation :update_expiry_time_based_on_seconds_to_live

  # Constants
  QUEUED = 0
  CHALLENGE_SENT = 1
  CONFIRMED = 2
  DENIED = 3
  FAILED = 4
  EXPIRED = 5
  
  ERROR_INVALID_TO = 101
  ERROR_INVALID_FROM = 102
  ERROR_BLACKLISTED_TO = 105
  ERROR_NOT_SMS_CAPABLE = 103
  ERROR_CANNOT_ROUTE = 104
  ERROR_SMS_QUEUE_FULL = 106

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
  validates_length_of :challenge_sms_sid, :is=>Twilio::SID_LENGTH, :allow_nil=>true
  validates_length_of :reply_sms_sid, :is=>Twilio::SID_LENGTH, :allow_nil=>true
  validates_length_of :response_sms_sid, :is=>Twilio::SID_LENGTH, :allow_nil=>true
  #validates_numericality_of :seconds_to_live
  
  # Scopes
  scope :opened, where( :status => [ QUEUED, CHALLENGE_SENT ] )
  scope :closed, where( :status => [ CONFIRMED, DENIED, FAILED, EXPIRED ] )
  scope :today, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day )
  scope :yesterday, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day )
  
  def update_expiry_time_based_on_seconds_to_live
    unless self.seconds_to_live.nil?
      ss = ( Float(self.seconds_to_live) rescue nil )
      self.expiry = ss.seconds.from_now unless ss.nil?
    end
  end
  
  ##
  # Send challenge SMS message. This will construct the appropriate SMS 'envelope' and pass to the +Ticket's+ +Account+. This will also convert
  # the results into a message, to be held for reference.
  def send_challenge( force_resend = false )
  
    # Abort if message already sent and we do not want to force a resend
    return nil if self.has_challenge_been_sent? and !force_resend
    
    # Otherwise, continue to send SMS and store the results
    #message = nil
    begin
      results = self.appliance.account.send_sms( self.to_number, self.from_number, self.question )
      message = self.messages.create!( twilio_sid: results.sid, payload: results.to_property_hash )
      return message

    rescue Twilio::REST::RequestError => ex
      self.status = case ex.code
        when 21211
          ERROR_INVALID_TO
        when 21212
          ERROR_INVALID_FROM
        when 21606, 21614
          ERROR_NOT_SMS_CAPABLE
        when 21611
          ERROR_SMS_QUEUE_FULL
        when 21612
          ERROR_CANNOT_ROUTE
        when 21610
          ERROR_BLACKLISTED_TO
        else
          raise ex
      end
      self.save
      return nil
    end

    #return message    
  end
  
  ##
  # Send reply SMS message, based upon the +Ticket's+ current state. This will construct the appropriate SMS 'envelope' and pass to the +Ticket's+ +Account+.
  def send_reply( force_resend = false )
  
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
    self.appliance.account.send_sms( self.to_number, self.from_number, reply_body )
    return self.messages.create( twilio_sid: results.sid, payload: results.to_property_hash );
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
end
