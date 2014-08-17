shared_examples 'a price sheet library' do

  describe '#price_sheet_for' do
    it 'gets a known country' do
      expect(subject.price_sheet_for('us')).to be_a PriceSheet
    end
    it 'raises error on unknown country' do
      expect{ subject.price_sheet_for('xxxx') }.to raise_error(SignalCloud::UnknownPriceSheetError)
    end
  end

end