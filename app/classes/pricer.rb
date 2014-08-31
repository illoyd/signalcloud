class Pricer

  attr_reader :config
  delegate :prices, to: :config

  def initialize(pricesheet = {})
    @config = pricesheet
  end
  
  def price_for( obj )
    raise NotImplementedError
  end

end