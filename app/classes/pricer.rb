class Pricer

  attr_reader :config

  def initialize(config = {})
    @config = config.with_indifferent_access
  end
  
  def price_for( obj )
    raise NotImplementedError
  end
  
end