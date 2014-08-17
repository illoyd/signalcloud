require 'spec_helper'
describe Pricer, :type => :model do
  it_behaves_like 'a pricer'
  
  describe '#price_for' do
    it 'throws an error!' do
      expect{ subject.price_for( 'us' ) }.to raise_error(NotImplementedError)
    end
  end

  describe '#price_sheet_library' do
    it 'provides a default library' do
      expect(subject.price_sheet_library.respond_to?(:price_sheet_for)).to be_truthy
    end
  end

end
