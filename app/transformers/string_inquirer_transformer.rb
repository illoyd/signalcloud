class StringInquirerTransformer

  def self.call(value)
    ActiveSupport::StringInquirer.new(value) rescue nil
  end

end
