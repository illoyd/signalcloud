class PhoneNumber < ActiveRecord::Base
  attr_accessible :account, :our_cost, :provider_cost
  
  #attr_encryptor :number, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :account, inverse_of: :phone_numbers
  has_many :phone_number_entries, inverse_of: :phone_number
end
