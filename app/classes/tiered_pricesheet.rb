class TieredPricesheet < Pricesheet

  def self.load(config)
    new(config['config']['multiple_of'], config['config']['min_margin'], config['prices'], config['source_type'])
  end
  
  ##
  # Create a new Tiered Pricesheet which can accept
  def initialize(multiple_of, min_margin, prices = nil, source = nil, force_refresh = false)
    super(prices)

    @multiple_of = multiple_of
    @min_margin  = min_margin
    @source      = source
    
    # Load prices immediately if given
    refresh_from_source if @source && force_refresh
  end
  
  def config
    { multiple_of: @multiple_of, min_margin: @min_margin }.with_indifferent_access
  end
  
  ##
  # Refresh the given pricesheet and convert into a tiered pricing strategy
  def refresh(pricesheet)
    # For every entry, make it a multiple
    @prices = HashWithIndifferentAccess[ pricesheet.map { |k,v| [k, round(v)] } ]
  end
  
  def refresh_from_source
    refresh(@source.constantize.parse) if @source
  end
  
  protected
  
  ##
  # Round up the given value + margin.
  def round(value)
    ( (value.to_f + @min_margin) / @multiple_of ).ceil * @multiple_of
  end

end