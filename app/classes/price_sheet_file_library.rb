require 'price_sheet'

class PriceSheetFileLibrary
  PRICESHEET_DIR = 'pricesheets'

  def price_sheet_for( country )
    filename = filename_for( country )
    raise SignalCloud::UnknownPriceSheetError.new( country ) unless File.exists? filename
    data = YAML.load_file filename
    PriceSheet.new( data[:country], data[:base_conversation_price], data[:base_phone_number_price] )
  end

  def save( price_sheet )
    data = {
      country:                 price_sheet.country.to_s,
      base_conversation_price: price_sheet.base_conversation_price,
      base_phone_number_price: price_sheet.base_phone_number_price
    }
    File.open( filename_for(price_sheet.country), 'w' ) do |f|
      f.write YAML.dump(data)
    end
  end
  
protected

  def filename_for(country)
    File.join( '.', PRICESHEET_DIR, "#{country.downcase}.yml" )
  end

end