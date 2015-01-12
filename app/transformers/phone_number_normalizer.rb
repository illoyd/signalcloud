class PhoneNumberNormalizer
  def self.call(value)
    value = value.phone_number if value.respond_to?(:phone_number)
    Country.plausible_phone_number?(value) ? Country.format_international_phone_number(value, spaces: '').gsub(/\s/, '') : value
  end
  
  self.singleton_class.send(:alias_method, :normalize, :call)
  self.singleton_class.send(:alias_method, :perform,   :call)
end