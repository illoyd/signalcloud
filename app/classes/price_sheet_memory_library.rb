require 'price_sheet'

class PriceSheetMemoryLibrary

  attr_accessor :library
  attr_reader :price_sheets

  def initialize( library=nil )
    @library = library || PriceSheetFileLibrary.new
    @price_sheets = HashWithIndifferentAccess.new
  end

  def price_sheet_for( country )
    country = country.to_s.upcase
    self.price_sheets[country] ||= self.library.price_sheet_for(country)
  end
  
  def memoize( price_sheet )
    country = price_sheet.country.to_s.upcase
    self.price_sheets[country] = price_sheet
  end

end