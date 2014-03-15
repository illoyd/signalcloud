class PhoneTools < Struct

  def self.normalize(number)
    Phony.normalize number
  end
  
  def self.plausible?(number)
    Phony.plausible? number
  end
  
  def self.componentize(number)
    Phony.split(Phony.normalize(number))
  end

  def self.humanize(number)
    Countries::PhoneNumbers.format_international_phone_number(number)
  end
  
  def self.country(number)
    Country.find_country_by_phone_number(number).alpha2.to_sym
  end
  
end
