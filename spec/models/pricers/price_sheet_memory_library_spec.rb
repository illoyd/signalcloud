require 'spec_helper'
describe PriceSheetMemoryLibrary do
  it_behaves_like 'a price sheet library'

  describe '#price_sheet_for' do
    it 'memorises price sheets' do
      expect{ subject.price_sheet_for('us') }.to change(subject, :price_sheets)
    end
    it 'memoises the country sheet as a symbol' do
      subject.price_sheet_for('us')
      subject.price_sheets.should include( :US )
    end
    it 'memoises the country sheet as a string' do
      subject.price_sheet_for('us')
      subject.price_sheets.should include( 'US' )
    end
    it 'stores requested price sheet' do
      subject.price_sheet_for('us')
      subject.price_sheets[:US].should be_a PriceSheet
    end
  end

end
