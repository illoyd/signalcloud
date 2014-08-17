require 'spec_helper'
describe PriceSheet, :type => :model do
  subject { PriceSheet.new :US }
  
  describe '#base_conversation_price' do
    it 'returns BigDecimal' do
      expect(subject.base_conversation_price).to be_a BigDecimal
    end
  end

  describe '#base_phone_number_price' do
    it 'returns BigDecimal' do
      expect(subject.base_phone_number_price).to be_a BigDecimal
    end
  end

end
