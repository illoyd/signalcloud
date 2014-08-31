class Pricesheet

  attr_accessor :prices, :source
  
  def self.load(config)
    return nil if config.nil?

    config = JSON.parse(config)
    klass = config['type'].constantize
    klass.load(config)
  end
  
  def self.dump(object)
    object.to_config.to_json
  end
  
  def initialize(prices)
    @prices = prices.try(:with_indifferent_access) || HashWithIndifferentAccess.new
  end
  
  def dup
    Pricesheet.load(Pricesheet.dump(self))
  end
  
  ##
  # Return configuration suitable for use with the pricers.
  def to_config
    HashWithIndifferentAccess.new({
      type:        self.class.to_s,
      config:      self.config,
      prices:      self.prices,
      source_type: self.source
    })
  end
  
  def diff(other)
    HashDiff.diff(self.to_config, other.to_config)
  end

end