require 'price_sheet'

class PriceSheetFileLibrary
  PRICESHEET_DIR = 'pricesheets'

  def price_sheet_for( country )
    filename = filename_for( country )
    raise SignalCloud::UnknownPriceSheetError.new( country ) unless File.exists? filename
    YAML.load_file filename
  end

  def save( price_sheet )
    File.open( filename_for(country), 'w' ) do |f|
      f.write YAML.dump(self)
    end
  end
  
protected

  def filename_for(country)
    File.join( '.', PRICESHEET_DIR, "#{country.downcase}.yml" )
  end

end