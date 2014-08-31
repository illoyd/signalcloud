require 'spec_helper'
fdescribe Pricer, :type => :model do
  it_behaves_like 'a pricer'
  
  describe '#price_for' do
    it 'throws an error!' do
      expect{ subject.price_for( 'us' ) }.to raise_error(NotImplementedError)
    end
  end

end
