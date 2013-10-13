require 'spec_helper'

describe AccountPlan do

  PROVIDER_COSTS = %w( 0.00, 0.01, 0.02, 0.03, 0.04, 0.044, 0.077, 0.10, 0.11, 1.00, 1.50, 2.00, 100.00 ).map{ |e| -BigDecimal.new(e) }
  ADDITION_VALUES = %w( 0.0, 0.001, 0.01, 0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0 ).map{ |e| -BigDecimal.new(e) }
  MULTIPLIER_VALUES = %w( 0.0, 0.8, 0.9, 1.0, 1.001, 1.01, 1.1, 1.11, 1.5, 2.0 ).map{ |e| BigDecimal.new(e) }
  
  describe '#price_for' do
    let(:conversation)   { build_stubbed :conversation }
    let(:phone_number)   { build_stubbed :phone_number }
    let(:us_price_sheet) { PriceSheet.new :US, 0.1, 1.0 }
    before do
      subject.phone_number_pricer.price_sheet_library.memoize( us_price_sheet )
      subject.conversation_pricer.price_sheet_library.memoize( us_price_sheet )
    end

    it 'can price a conversation' do
      subject.price_for( conversation ).should be_a BigDecimal
    end

    it 'can price a phone_number' do
      subject.price_for( phone_number ).should be_a BigDecimal
    end

    it 'cannot price a string' do
      expect{ subject.price_for( 'string' ) }.to raise_error( SignalCloud::UnpriceableObjectError )
    end

  end
  
  describe '#phone_number_pricer' do
    it 'returns a pricer' do
      subject.phone_number_pricer.should be_a Pricer
    end
  end

  describe '#conversation_pricer' do
    it 'returns a pricer' do
      subject.conversation_pricer.should be_a Pricer
    end
  end

end
