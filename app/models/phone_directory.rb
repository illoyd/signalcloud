class PhoneDirectory < ActiveRecord::Base
  attr_accessible :description, :label
  
  belongs_to :account, inverse_of: :phone_directories
  has_many :appliances, inverse_of: :phone_directory
  has_many :phone_directory_entries, inverse_of: :phone_directory, :order => 'country'
  
  def select_from_number( to_number )
    # TODO: FIX ME!
    self.phone_directory_entries.first.phone_number.number
  end
end
