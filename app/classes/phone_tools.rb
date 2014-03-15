class PhoneTools < Struct

  def self.country(number)
    Country.find_country_by_phone_number(number).alpha2.to_sym
  end
  
end
