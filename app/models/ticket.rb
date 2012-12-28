class Ticket < ActiveRecord::Base

  before_validation :update_expiry_time_based_on_seconds_to_live

  # Constants
  QUEUED = 0
  CHALLENGE_SENT = 1
  CONFIRMED = 2
  DENIED = 3
  FAILED = 4
  EXPIRED = 5

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
  
  # Validation
  validates_presence_of :appliance, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry
  validates_length_of :challenge_sms_sid, :is=>34, :allow_nil=>true
  validates_length_of :reply_sms_sid, :is=>34, :allow_nil=>true
  validates_length_of :response_sms_sid, :is=>34, :allow_nil=>true
  #validates_numericality_of :seconds_to_live
  
  # Scopes
  scope :opened, where( :status => [ QUEUED, CHALLENGE_SENT ] )
  scope :closed, where( :status => [ CONFIRMED, DENIED, FAILED, EXPIRED ] )
  scope :today, where( "tickets.created_at >= ?", Time.now.beginning_of_day )
  scope :yesterday, where( "tickets.created_at >= ? and tickets.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day )
  
  def update_expiry_time_based_on_seconds_to_live
    if !self.seconds_to_live.nil? 
      self.expiry = self.seconds_to_live.to_i.seconds.from_now
    end
  end
end
