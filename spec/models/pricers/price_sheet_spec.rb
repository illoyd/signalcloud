require 'spec_helper'
describe PriceSheet do
  subject { PriceSheet.new :US }
  
  describe '#base_conversation_price' do
    it 'returns BigDecimal' do
      subject.base_conversation_price.should be_a BigDecimal
    end
  end

  describe '#base_phone_number_price' do
    it 'returns BigDecimal' do
      subject.base_phone_number_price.should be_a BigDecimal
    end
  end

end
