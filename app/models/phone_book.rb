class PhoneBook < ActiveRecord::Base
  
  # Relationships
  belongs_to :organization, inverse_of: :phone_books
  has_many :stencils, inverse_of: :phone_book, dependent: :restrict_with_error
  has_many :phone_book_entries, inverse_of: :phone_book, dependent: :destroy
  has_many :phone_numbers, through: :phone_book_entries #, select: 'phone_numbers.*, phone_book_entries.country AS country'
  
  # Validations
  validates_presence_of :organization
  
  # Normalizations
  normalize_attributes :label, :description
  
  ##
  # Return phone numbers for the specified country. Pass +nil+ to find 'global' phone numbers.
  def phone_numbers_by_country(country)
    self.phone_numbers.with_active_state.where(phone_book_entries: {country: country})
  end
  
  ##
  # Return all global phone numbers.
  def default_phone_numbers
    self.phone_numbers_by_country(nil)
  end
  
  ##
  # Return a random number from this book for the given number.
  def select_internal_number_for( to_number )
    country = PhoneTools.country to_number
    country = country.to_s if country.respond_to? :to_s

    # First, try to find 'From numbers' for the same country as the country for the 'To number'
    phone_numbers = self.phone_numbers_by_country(country)
    
    # If no phone numbers found, try the 'global' (nil country) phone numbers
    phone_numbers = self.default_phone_numbers if phone_numbers.empty?
    
    # If still no number is found, grab all phone numbers
    phone_numbers = self.phone_numbers if phone_numbers.empty?

    # Finally, randomly select one phone number from the collection
    return phone_numbers.sample
  end

end
