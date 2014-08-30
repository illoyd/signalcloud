class MiniPhoneNumber
  include Comparable
  include AttributeNormalizer
  
  attr_accessor :phone_number
  normalize_attribute :phone_number, with: :phone_number
  
  def initialize(pn)
    self.phone_number = pn
  end
  
  def country
    @country ||= Country.find_country_by_phone_number(@phone_number)
  end
  
  def alpha2
    country.alpha2
  end
  
  def plausible?
    Country.plausible_phone_number?(@phone_number)
  end
  
  def to_s
    @phone_number.to_s
  end
  
  def eql?(other)
    other.to_s == to_s
  end
  
  def <=>(other)
    other.to_s <=> self.to_s
  end

  def self.dump(object)
    object.to_s
  end
  
  def self.load(value)
    value.nil? ? nil : new(value.to_s)
  end
  
end