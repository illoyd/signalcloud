class Address < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country, :organization_id
  belongs_to :organization
  validates_presence_of :first_name, :last_name, :email
end
