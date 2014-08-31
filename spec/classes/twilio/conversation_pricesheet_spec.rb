require 'spec_helper'

fdescribe Twilio::ConversationPricesheet, :vcr do

  describe '.parse' do
    
    it 'downloads without error' do
      expect{ described_class.parse }.not_to raise_error
    end
    
    it 'returns a hash' do
      expect( described_class.parse ).to be_a(Hash)
    end

  end

end