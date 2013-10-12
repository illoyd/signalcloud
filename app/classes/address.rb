##
# A simple value object for storing addresses on objects. This is primarily intended for use by the Organization class
# for the #billing_address and #mailing_address fields.
class Address
  include Comparable
  attr_reader :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country
  
  ##
  # Initialize with all values.
  def initialize( first_name=nil, last_name=nil, email=nil, work_phone=nil, line1=nil, line2=nil, city=nil, region=nil, postcode=nil, country=nil )
    @first_name, @last_name, @email, @work_phone, @line1, @line2, @city, @region, @postcode, @country = first_name, last_name, email, work_phone, line1, line2, city, region, postcode, country
  end
  
  ##
  # Compare against another object...
  def <=>( other )
    [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].reverse.each do |attribute|
      comparison = try(attribute) <=> other.try(attribute)
      return comparison if comparison != 0
    end
    0
  end

end