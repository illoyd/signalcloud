class PhoneDirectory < ActiveRecord::Base
  attr_accessible :description, :label
  
  belongs_to :account, inverse_of: :phone_directories
  has_many :appliances, inverse_of: :phone_directory
  has_many :phone_directory_entries, inverse_of: :phone_directory, :order => 'country'
  has_many :phone_numbers, through: :phone_directory_entries #, select: 'phone_numbers.*, phone_directory_entries.country AS country'
  
  def phone_numbers_by_country( country )
    self.phone_numbers.where( 'phone_directory_entries.country' => country )
  end
  
  def default_phone_numbers()
    self.phone_numbers_by_country(nil)
  end
  
  def country_for_number( number )
    return case
      when PhoneTools.united_states?(number)
        PhoneDirectoryEntry::US
      when PhoneTools.canadian?(number)
        PhoneDirectoryEntry::CA
      when PhoneTools.united_kingdom?(number)
        PhoneDirectoryEntry::GB
      else
        PhoneDirectoryEntry::DEFAULT
    end
  end
  
  def select_from_number( to_number )
    # Attempt to map the given number into a country
    components = PhoneTools.componentize to_number

    # Read first component - this is usually the country code
    country = case components.first.to_i
      # For North American numbers, look at second component
      when PhoneTools::NANP_CODE
        if PhoneTools.other_nanp_country?(components.second.to_i)
          PhoneDirectoryEntry::DEFAULT
        elsif PhoneTools.canadian?(components.second.to_i)
          PhoneDirectoryEntry::CA
        else
          PhoneDirectoryEntry::US
        end
      when PhoneTools::GB_CODE
        PhoneDirectoryEntry::GB
      else
        PhoneDirectoryEntry::DEFAULT
    end
    
    country = self.country_for_number to_number

    # Return a random entry from the given country set
    # Tests for requested country, then nil country, then finally the first number available
    #puts 'country: %s; array: %s' % [ country, components ]
    phone_number_ids = self.phone_directory_entries.where( country: country ).pluck(:phone_number_id)
    phone_number_ids = self.phone_directory_entries.where( country: nil ).pluck(:phone_number_id) if phone_number_ids.empty?
    return self.phone_directory_entries.first.phone_number if phone_number_ids.empty?
    return PhoneNumber.find(phone_number_ids.sample)
  end

end
