class PhoneNumber < ActiveRecord::Base
  attr_accessible :number, :twilio_phone_number_sid, :account_id, :our_cost, :provider_cost
  
  attr_encrypted :number, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :account, inverse_of: :phone_numbers
  has_many :phone_number_entries, inverse_of: :phone_number
  has_many :phone_directories, through: :phone_number_entries
  
  validates_presence_of :account_id, :twilio_phone_number_sid, :number
  validates_uniqueness_of :twilio_phone_number_sid

  def cost
    return self.provider_cost + self.our_cost
  end
  
  def buy
    results = self.account.twilio_account.incoming_phone_numbers.create( { phone_number: self.number } )
    self.twilio_phone_number_sid = results.sid
    return results
  end

end
