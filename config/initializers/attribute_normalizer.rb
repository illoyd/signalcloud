AttributeNormalizer.configure do |config|

  # The default normalizers if no :with option or block is given is to apply the :strip and :blank normalizers (in that order).
  # You can change this if you would like as follows:
  # config.default_normalizers = :strip, :blank

  # You can enable the attribute normalizers automatically if the specified attributes exist in your column_names. It will use
  # the default normalizers for each attribute (e.g. config.default_normalizers)
  # config.default_attributes = :name, :title
  config.default_attributes = :label, :description

  # Also, You can add a specific attribute to default_attributes using one or more normalizers:
  # config.add_default_attribute :name, :with => :truncate
  
  config.normalizers[:currency] = lambda do |value, options|
    value.is_a?(String) ? value.gsub(/[^0-9\.]+/, '') : value
  end

  config.normalizers[:truncate] = lambda do |text, options|
    if text.is_a?(String)
      options.reverse_merge!(:length => 30, :omission => "...")
      l = options[:length] - options[:omission].mb_chars.length
      chars = text.mb_chars
      (chars.length > options[:length] ? chars[0...l] + options[:omission] : text).to_s
    else
      text
    end
  end
  
  config.normalizers[:upcase] = ->(value, options) {
    value.try(:upcase) || value
  }
  
  config.normalizers[:downcase] = ->(value, options) {
    value.try(:downcase) || value
  }
  
  config.normalizers[:phone_number] = ->(value, options) {
    Country.plausible_phone_number?(value) ? Country.format_international_phone_number(value, spaces: '').gsub(/\s/, '') : value
  }
  
  config.normalizers[:postcode] = ->(value, options) {
    attribute = options[:country_attribute]
    country = options[:object].send(attribute)
    GoingPostal.postcode?(value, country) ? GoingPostal.format_postcode(value, country) : value
  }

end