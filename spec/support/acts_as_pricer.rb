shared_examples 'a pricer' do

  describe '#price_for' do
    it 'responds to #price_for' do
      expect(subject.respond_to?(:price_for)).to be_truthy
    end
  end

  describe '#price_sheet_library' do
    it 'responds to #price_sheet_library' do
      expect(subject.respond_to?(:price_sheet_library)).to be_truthy
    end
  end

end