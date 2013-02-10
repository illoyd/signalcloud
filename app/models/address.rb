class Address < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country, :account_id
  belongs_to :account
  
  validates_presence_of :first_name, :last_name, :email, :city, :region, :postcode, :country
  
  #validates_existence_of :account

end
