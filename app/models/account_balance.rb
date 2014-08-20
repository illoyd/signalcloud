class AccountBalance < ActiveRecord::Base
  belongs_to :organization, inverse_of: :account_balance
  validates_presence_of :organization
  validates_numericality_of :balance
  attr_readonly :balance

  #attr_accessor :balance_changed
  
  def update_balance!(delta)
    balance_will_change! unless delta == 0
    self.class.update_counters( self.id, balance: delta )
    
    #self.class.where( id: self.id ).update_all( ['balance = balance + ?', delta] )
    #self.balance_changed = true
  end
  
  def balance
    self.reload if self.balance_changed?
    super
  end

end
