class PhoneDirectory < ActiveRecord::Base
  attr_accessible :description, :label
  
  belongs_to :account, inverse_of: :phone_directories
  has_many :appliances, inverse_of: :phone_directory
  has_many :phone_directory_entries, inverse_of: :phone_directory, :order => 'country'
  
  def select_from_number( to_number )
    # Attempt to map the given number into a country
    components = PhoneTools.componentize to_number

    # Read first component - this is usually the country code
    country = case components.first
      # For North American numbers, look at second component
      when PhoneTools::NANP_CODE
        PhoneDirectoryEntry::DEFAULT if PhoneTools.other_nanp_country?(components.second)
        PhoneTools.canadian?(components.second) ? PhoneDirectoryEntry::CA : PhoneDirectoryEntry::US
      when PhoneTools::GB_CODE
        PhoneDirectoryEntry::GB
      else
        PhoneDirectoryEntry::DEFAULT
    end

    # Return a random entry from the given country set
    phone_number_ids = self.phone_directory_entries.where( country: country ).pluck(:phone_number_id)
    phone_number_ids = self.phone_directory_entries.where( country: nil ).pluck(:phone_number_id) if phone_number_ids.empty?
    phone_number_ids = self.phone_directory_entries.first if phone_number_ids.empty?
    PhoneNumber.find(phone_number_ids.sample).number
  end

end
