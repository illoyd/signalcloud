class PhoneDirectory < ActiveRecord::Base
  attr_accessible :description, :label
  
  belongs_to :account, inverse_of: :phone_directories
  has_many :appliances, inverse_of: :phone_directory
  has_many :phone_directory_entries, inverse_of: :phone_directory, :order => 'country'
  
  def select_from_number( to_number )
    # Attempt to map the given number into a country
    components = Phony.split( Phony.normalize(to_number) )

    # Read first component - this is usually the country code
    country = case components.first
      # For North American numbers, look at second component
      when 1
        nil if Phony.not_canadian_or_united_states?(components.second)
        'CA' if Phony.canadian?(components.second) ? 'CA' : 'US'
      when 44
        'GB'
      else
        nil
    end

    # Return a random entry from the given country set
    self.phone_directory_entries.first.phone_number.number
  end

end
