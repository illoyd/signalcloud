class PhoneNumber < ActiveRecord::Base
  attr_accessible :number, :twilio_phone_number_sid, :account_id, :our_cost, :provider_cost
  
  attr_encrypted :number, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :account, inverse_of: :phone_numbers
  has_many :phone_directory_entries, inverse_of: :phone_number
  has_many :phone_directories, through: :phone_directory_entries
  
  validates_presence_of :account, :account_id, :twilio_phone_number_sid, :number
  validates_numericality_of :our_cost, :provider_cost, :account_id
  
  validates_length_of :twilio_phone_number_sid, is: 34
  validates_uniqueness_of :twilio_phone_number_sid, :case_sensitive => false

  def cost
    return self.provider_cost + self.our_cost
  end
  
  
  def buy
    # If not assigned to an account, cannot buy a number!
    raise TicketpleaseError.new( 'PhoneNumber not associated to an Account' ) if self.account.nil?
    results = self.account.twilio_account.incoming_phone_numbers.create( { phone_number: self.number, application_sid: self.account.twilio_application_sid } )
    self.twilio_phone_number_sid = results.sid
    return results
  end

end
