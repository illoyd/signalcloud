shared_examples 'a pricer' do

  describe '#price_for' do
    it 'responds to #price_for' do
      expect(subject.respond_to?(:price_for)).to be_truthy
    end
  end

  describe '#config' do
    it 'responds to #config' do
      expect(subject.respond_to?(:config)).to be_truthy
    end
  end

end