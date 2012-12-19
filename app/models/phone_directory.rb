class PhoneDirectory < ActiveRecord::Base
  attr_accessible :description, :name
  
  belongs_to :account, inverse_of: :phone_directories
  has_many :phone_directory_entries, inverse_of: :directory
end
