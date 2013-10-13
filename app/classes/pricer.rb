class Pricer

  attr_accessor :price_sheet_library
  delegate :price_sheet_for, to: :price_sheet_library
  
  def price_for( obj )
    raise NotImplementedError
  end
  
  def price_sheet_library
    @price_sheet_library ||= PriceSheetMemoryLibrary.new
  end

end