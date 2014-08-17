require 'spec_helper'
describe PhoneNumberPricer, :type => :model do
  it_behaves_like 'a pricer'
  
  describe '#price_for' do
    let(:us_price_sheet)  { PriceSheet.new 'us', 0.10, 1.5 }
    let(:gb_price_sheet)  { PriceSheet.new 'gb', 0.15, 2.0 }
    let(:us_phone_number) { build :us_phone_number }
    let(:gb_phone_number) { build :uk_phone_number }
    before(:each) do
      subject.price_sheet_library.memoize(us_price_sheet)
      subject.price_sheet_library.memoize(gb_price_sheet)
    end

    it 'no errors!' do
      expect{ subject.price_for( us_phone_number ) }.not_to raise_error()
    end

    it 'calculates a US number' do
      expect(subject.price_for( us_phone_number )).to eq(us_price_sheet.base_phone_number_price)
    end

    it 'calculates a UK number' do
      expect(subject.price_for( gb_phone_number )).to eq(gb_price_sheet.base_phone_number_price)
    end

  end #price_for

end
