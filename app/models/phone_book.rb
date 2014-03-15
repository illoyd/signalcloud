class PhoneBook < ActiveRecord::Base
  
  belongs_to :organization, inverse_of: :phone_books
  has_many :stencils, inverse_of: :phone_book
  has_many :phone_book_entries, inverse_of: :phone_book, dependent: :destroy
  has_many :phone_numbers, through: :phone_book_entries #, select: 'phone_numbers.*, phone_book_entries.country AS country'
  
  validates_presence_of :organization
  
  def phone_number_ids_by_country( country )
    self.phone_book_entries.where( country: country ).pluck(:phone_number_id)
  end
  
  def default_phone_number_ids()
    self.phone_number_ids_by_country(nil)
  end
  
  def select_internal_number_for( to_number )
    country = PhoneTools.country to_number
    country = country.to_s if country.respond_to? :to_s

    # First, try to find 'From numbers' for the same country as the country for the 'To number'
    phone_number_ids = self.phone_number_ids_by_country(country)
    
    # If no phone numbers found, try the 'global' phone numbers
    phone_number_ids = self.default_phone_number_ids if phone_number_ids.empty?
    
    # If still no number is found, grab any phone number from the book
    phone_number_ids = self.phone_book_entries.pluck(:phone_number_id) if phone_number_ids.empty?

    # Finally, randomly select one id from the collection and return that phone number
    return PhoneNumber.find(phone_number_ids.sample)
  end

end
