class PhoneBookEntry < ActiveRecord::Base
  US = 'US'
  CA = 'CA'
  GB = 'GB'
  UK = GB
  DEFAULT = nil

  COUNTRIES = ISO3166::Country::Names.map{ |(name,alpha2)| alpha2.to_s } # [ US, CA, GB ]

  attr_accessible :country, :phone_number_id, :phone_book_id

  belongs_to :phone_book, inverse_of: :phone_book_entries
  belongs_to :phone_number, inverse_of: :phone_book_entries
  
  validates_inclusion_of :country, in: COUNTRIES, allow_nil: true
  
  validates_presence_of :phone_number, :phone_book
  
  before_validation :standardise_country
  
  ##
  # Ensure that the currently set country is valid. If the country is not a recognised Alpha-2 code,
  # this will look up the current value and attempt to convert it to a country code.
  def standardise_country
    self.country.upcase! if ( not self.country.nil? and self.country.length == 2 and self.country != self.country.upcase)
  
    unless self.country.blank? or COUNTRIES.include? self.country
      country_data = ( Country.find_country_by_name( self.country ) or Country.find_country_by_alpha3( self.country ) ) rescue nil
      self.country = country_data.alpha2 if country_data
    end
    
    # Nil out the country if it is blank (ensures NULL database entries)
    self.country = nil if self.country.blank?
  end
  
end
