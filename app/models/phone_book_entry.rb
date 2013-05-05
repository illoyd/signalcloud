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
  
  def standardise_country
    country_data = Country.find_country_by_name( self.country ) rescue nil
    if country_data
      self.country = country_data.alpha2
    end
  end
  
end