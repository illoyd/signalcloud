class LedgerEntry < ActiveRecord::Base

  PENDING = 0
  SETTLED = 1
  
  UNKNOWN_NARRATIVE = 'Activity under research'
  OUTBOUND_SMS_NARRATIVE = 'Outbound SMS'
  INBOUND_SMS_NARRATIVE = 'Inbound SMS'
  UNSOLICITED_SMS_NARRATIVE = 'Unsolicited Inbound SMS'
  UNSOLICITED_SMS_REPLY_NARRATIVE = 'Reply to Unsolicited Inbound SMS'
  INBOUND_CALL_NARRATIVE = 'Inbound Phone Call'

  attr_accessible :narrative, :value, :settled_at, :organization_id, :item_id, :item_type, :organization, :item, :notes, :invoiced_at
  
  belongs_to :organization, inverse_of: :ledger_entries
  belongs_to :invoice, inverse_of: :ledger_entries
  belongs_to :item, polymorphic: true
  
  validates_presence_of :organization, :narrative
  validates_numericality_of :value, allow_nil: true
  
  before_validation :ensure_organization
  before_save :update_organization_balance
  
  ##
  # Find all ledger_entries which have not been confirmed.
  # This usually implies that the 'value' may change based upon the provider's response.
  scope :pending, ->{ where( 'settled_at is null' ) }
  
  ##
  # Find all ledger_entries which have been confirmed.
  # This usually entails the 'value' is set to a permanent figure.
  scope :settled, ->{ where( 'settled_at is not null' ) }
  
  ##
  # Find all ledger_entries which have not been invoiced.
  scope :uninvoiced, ->{ where( 'invoice_id is null' ) }

  ##
  # Find all ledger_entries which have been invoiced.
  scope :invoiced, ->{ where( 'invoice_id is not null' ) }
  
  ##
  # Find all where settled before a given date
  scope :settled_before, ->( to_date ){ where( 'settled_at <= ?', to_date )}

  ##
  # Get all entries created yesterday.
  scope :in_range, ->( from_date, to_date ){ where( "ledger_entries.created_at >= ? and ledger_entries.created_at <= ?", from_date, to_date ) }
  
  ##
  # Get all entries created today.
  #scope :today, ->{ where( "ledger_entries.created_at >= ? and ledger_entries.created_at <= ?", DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  scope :today, ->{ in_range( DateTime.now.beginning_of_day, DateTime.now.end_of_day ) }
  
  ##
  # Get all entries created yesterday.
  #scope :yesterday, ->{ where( "ledger_entries.created_at >= ? and ledger_entries.created_at <= ?", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  scope :yesterday, ->{ in_range( DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day ) }
  
  ##
  # Get all debits (negative or zero) charges
  scope :debits, ->{ where( 'value <= 0' ) }

  ##
  # Get all credits (positive) charges
  scope :credits, ->{ where( 'value > 0' ) }

  ##
  # Simple test if status is pending (e.g. has not been confirmed by the provider)
  def pending?
    return self.settled_at.nil?
  end
  
  ##
  # Simple test if status is settled (e.g. has been confirmed by the provider)
  def settled?
    return !self.pending?
  end
  
  alias is_pending? pending?
  alias is_settled? settled?
  
  ##
  # Ensure that the parent organization is the same as the item's organization
  def ensure_organization
    if self.item.is_a?(Organization)
      self.organization = self.item
    else
      self.organization = self.item.organization unless self.item.try(:organization).nil?
    end
    #self.organization_id = self.organization.id unless self.organization.try(:id).nil?
  end
  
  def update_organization_balance
    difference = ( self.value || 0 ) - ( self.value_was || 0 )
    return if difference == 0
    self.organization.update_balance! difference
  end

end
