require 'spec_helper'
describe Pricer do
  it_behaves_like 'a pricer'
  
  describe '#price_for' do
    it 'throws an error!' do
      expect{ subject.price_for( 'us' ) }.to raise_error(NotImplementedError)
    end
  end

  describe '#price_sheet_library' do
    it 'provides a default library' do
      subject.price_sheet_library.respond_to?(:price_sheet_for).should be_true
    end
  end

end
