class Transaction < ActiveRecord::Base

  PENDING = 0
  SETTLED = 1

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
