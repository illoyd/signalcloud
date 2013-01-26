class Address < ActiveRecord::Base
  attr_accessible :line1, :line2, :city, :region, :postcode, :country, :account_id
  belongs_to :account

end
