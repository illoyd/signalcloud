class PhoneBook < ActiveRecord::Base
  attr_accessible :description, :label
  
  belongs_to :organization, inverse_of: :phone_books
  has_many :stencils, inverse_of: :phone_book
  has_many :phone_book_entries, inverse_of: :phone_book, order: 'country', dependent: :destroy
  has_many :phone_numbers, through: :phone_book_entries #, select: 'phone_numbers.*, phone_book_entries.country AS country'
  
  def phone_numbers_by_country( country )
    self.phone_numbers.where( 'phone_book_entries.country' => country )
  end
  
  def default_phone_numbers()
    self.phone_numbers_by_country(nil)
  end
  
  def country_for_number( number )
    return case
      when PhoneTools.united_states?(number)
        PhoneBookEntry::US
      when PhoneTools.canadian?(number)
        PhoneBookEntry::CA
      when PhoneTools.united_kingdom?(number)
        PhoneBookEntry::GB
      else
        PhoneBookEntry::DEFAULT
    end
  end
  
  def select_from_number( to_number )
    country = self.country_for_number to_number

    # Return a random entry from the given country set
    # Tests for requested country, then nil country, then finally the first number available
    #puts 'country: %s; array: %s' % [ country, components ]
    phone_number_ids = self.phone_book_entries.where( country: country ).pluck(:phone_number_id)
    phone_number_ids = self.phone_book_entries.where( country: nil ).pluck(:phone_number_id) if phone_number_ids.empty?
    return self.phone_book_entries.first.phone_number if phone_number_ids.empty?
    return PhoneNumber.find(phone_number_ids.sample)
  end

end
