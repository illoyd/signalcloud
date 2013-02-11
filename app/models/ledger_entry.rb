class LedgerEntry < ActiveRecord::Base

  PENDING = 0
  SETTLED = 1
  
  OUTBOUND_SMS_NARRATIVE = 'Outbound SMS'
  INBOUND_SMS_NARRATIVE = 'Inbound SMS'
  UNSOLICITED_SMS_NARRATIVE = 'Unsolicited Inbound SMS'
  UNSOLICITED_SMS_REPLY_NARRATIVE = 'Reply to Unsolicited Inbound SMS'
  INBOUND_CALL_NARRATIVE = 'Inbound Phone Call'

  attr_accessible :narrative, :value, :settled_at, :account_id, :item_id, :item_type, :account, :item, :notes
  
  belongs_to :account, inverse_of: :ledger_entries
  belongs_to :item, polymorphic: true
  
  #validates_presence_of :account_id, :item_id, :item_type, :narrative
  validates_presence_of :account_id, :item_type, :narrative
  validates_presence_of :item_id, :unless => Proc.new { |a|
    #if it's a new record and addressable is nil and addressable_type is set
    #   then try to find the addressable object in the ObjectSpace
    #       if the addressable object exists, then we're valid;
    #       if not, let validates_presence_of do it's thing
    if (new_record? && !item && item_type)
      item = nil
      ObjectSpace.each_object(item_type.constantize) do |o|
        item = o if o.ledger_entry == a unless item
      end
    end
    item
  }
  validates_numericality_of :value, allow_nil: true
  
  before_validation :ensure_account
  
  ##
  # Find all ledger_entries which have not been confirmed.
  # This usually implies that the 'value' may change based upon the provider's response.
  scope :pending, where( 'settled_at is null' )
  
  ##
  # Find all ledger_entries which have been confirmed.
  # This usually entails the 'value' is set to a permanent figure.
  scope :settled, where( 'settled_at is not null' )

  ##
  # Get all entries created today.
  scope :today, ->{ where( "ledger_entries.created_at >= ? and ledger_entries.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  
  ##
  # Get all entries created yesterday.
  scope :yesterday, ->{ where( "ledger_entries.created_at >= ? and ledger_entries.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  
  ##
  # Get all debits (negative or zero) charges
  scope :debits, where( 'value <= 0' )

  ##
  # Get all credits (positive) charges
  scope :credits, where( 'value > 0' )

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
  
  ##
  # Ensure that the parent account is the same as the item's account
  def ensure_account
    self.account_id = self.item.account.id if !self.item.nil? #and self.item.respond_to?(:account)
  end

end
