class Transaction < ActiveRecord::Base

  PENDING = 0
  SETTLED = 1
  
  OUTBOUND_SMS_NARRATIVE = 'Outbound SMS'
  INBOUND_SMS_NARRATIVE = 'Inbound SMS'
  INBOUND_CALL_NARRATIVE = 'Inbound Phone Call'

  attr_accessible :narrative, :value, :settled_at, :account_id, :item_id, :item_type, :account, :item
  
  belongs_to :account, inverse_of: :transactions
  belongs_to :item, polymorphic: true
  
  validates_presence_of :account_id, :item_id, :item_type, :narrative
  validates_numericality_of :value, allow_nil: true
  
  ##
  # Find all transactions which have not been confirmed
  # This usually implies that the 'value' may change based upon the provider's response.
  scope :pending, where( 'settled_at is null' )
  
  
  ##
  # Find all transactions which have been confirmed.
  # This usually entails the 'value' is set to a permanent figure.
  scope :settled, where( 'settled_at is not null' )

  scope :today, where( "transactions.created_at >= ? and transactions.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day )
  scope :yesterday, where( "transactions.created_at >= ? and transactions.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day )

  ##
  # Simple test if status is pending (e.g. has not been confirmed by the provider)
  def is_pending?
    return self.settled_at.nil?
  end
  
  ##
  # Simple test if status is settled (e.g. has been confirmed by the provider)
  def is_settled?
    return !self.settled_at.nil?
  end

end
