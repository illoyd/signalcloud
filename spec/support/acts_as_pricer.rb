shared_examples 'a pricer' do

  describe '#price_for' do
    it 'responds to #price_for' do
      subject.respond_to?(:price_for).should be_true
    end
  end

  describe '#price_sheet_library' do
    it 'responds to #price_sheet_library' do
      subject.respond_to?(:price_sheet_library).should be_true
    end
  end

end