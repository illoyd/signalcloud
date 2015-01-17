class PhoneBookEntry < ActiveRecord::Base
  belongs_to :phone_book,   inverse_of: :phone_book_entries
  belongs_to :phone_number, inverse_of: :phone_book_entries
  
  validates_presence_of :phone_book, :phone_number
  validates_uniqueness_of :country, scope: [ :phone_book, :phone_number ]
  
  normalize_attributes :country
  
  def team
    phone_book.try(:team)
  end
end
