require 'spec_helper'

fdescribe MakeTwilioConversationTieredPricesheetJob, :vcr do
  
  describe '#perform' do
    context 'with multiple of 0.10 and minimum margin of 0.01' do
      let(:multiple_of) { 0.10 }
      let(:min_margin)  { 0.01 }
      
      it 'returns a hash of prices' do
        expect( subject.perform(multiple_of, min_margin) ).to be_a(Hash)
      end
      
      it 'does not give any prices less than multiple' do
        expect( subject.perform(multiple_of, min_margin).select { |_,v| v < multiple_of } ).to be_empty
      end
    end

    context 'with multiple of 0.05 and minimum margin of 0.02' do
      let(:multiple_of) { 0.05 }
      let(:min_margin)  { 0.02 }
      
      it 'returns a hash of prices' do
        expect( subject.perform(multiple_of, min_margin) ).to be_a(Hash)
      end
      
      it 'does not give any prices less than multiple' do
        expect( subject.perform(multiple_of, min_margin).select { |_,v| v < multiple_of } ).to be_empty
      end
    end
  end

end
