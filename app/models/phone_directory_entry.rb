class PhoneDirectoryEntry < ActiveRecord::Base
  attr_accessible :country
  
  belongs_to :phone_directory, inverse_of: :phone_directory_entries
  belongs_to :phone_number, inverse_of: :phone_directory_entry
end
