require 'spec_helper'

fdescribe MakeTwilioPhoneNumberTieredPricesheetJob, :vcr do
  
  describe '#perform' do
    context 'with multiple of 3 and minimum margin of 1' do
      let(:multiple_of) { 3 }
      let(:min_margin)  { 1 }
      
      it 'returns a hash of prices' do
        expect( subject.perform(multiple_of, min_margin) ).to be_a(Hash)
      end
      
      it 'does not give any prices less than multiple' do
        expect( subject.perform(multiple_of, min_margin).select { |_,v| v < multiple_of } ).to be_empty
      end
    end

    context 'with multiple of 2 and minimum margin of 0.5' do
      let(:multiple_of) { 2 }
      let(:min_margin)  { 0.5 }
      
      it 'returns a hash of prices' do
        expect( subject.perform(multiple_of, min_margin) ).to be_a(Hash)
      end
      
      it 'does not give any prices less than multiple' do
        expect( subject.perform(multiple_of, min_margin).select { |_,v| v < multiple_of } ).to be_empty
      end
    end
  end

end
