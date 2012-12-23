class Ticket < ActiveRecord::Base

  # Constants
  QUEUED = 0
  CHALLENGE_SENT = 1
  CONFIRMED = 2
  DENIED = 3
  FAILED = 4
  EXPIRED = 5

  #attr_accessible :appliance, :challenge_sent, :challenge_sms_sid, :encrypted_actual_answer, :encrypted_confirmed_reply, :encrypted_denied_reply, :encrypted_expected_confirmed_answer, :encrypted_expected_denied_answer, :encrypted_expired_reply, :encrypted_failed_reply, :encrypted_from_number, :encrypted_question, :encrypted_to_number, :expiry, :reply_sent, :reply_sms_sid, :response_received, :response_sms_sid, :status
  attr_accessible :challenge_sent, :challenge_sms_sid, :expiry, :reply_sent, :reply_sms_sid, :response_received, :response_sms_sid, :status
  
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
  
  # Scopes
  scope :opened, where( :status => [ QUEUED, CHALLENGE_SENT ] )
  scope :closed, where( :status => [ CONFIRMED, DENIED, FAILED, EXPIRED ] )
  scope :today, where( "tickets.created_at >= ?", Time.now.beginning_of_day )
  scope :yesterday, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day )
end
