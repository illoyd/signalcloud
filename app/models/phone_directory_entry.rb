class PhoneDirectoryEntry < ActiveRecord::Base
  US = 'US'
  CA = 'CA'
  GB = 'GB'
  UK = GB
  DEFAULT = nil
  COUNTRIES = [ US, CA, GB ]

  attr_accessible :country, :phone_number_id, :phone_directory_id  

  belongs_to :phone_directory, inverse_of: :phone_directory_entries
  belongs_to :phone_number, inverse_of: :phone_directory_entries
  
  validates_inclusion_of :country, in: COUNTRIES, allow_nil: true
  
end
