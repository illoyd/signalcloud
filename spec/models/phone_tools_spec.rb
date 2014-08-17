describe 'PhoneTools', :type => :model do

  describe '.country' do
    let(:us_number) { '12151234567' }
    let(:ca_number) { '14161234567' }
    let(:ch_number) { '41443643533' }
    let(:uk_number) { '447540186577' }
    let(:tt_number) { '18681234567' }
    let(:my_number) { '60123959999' }
    let(:au_number) { '61418123456' }
    let(:ru_number) { '79111234567' }
    let(:hk_number) { '85212345678' }
    
    it 'recognises US number' do
      expect(PhoneTools.country( us_number )).to eq(:US)
    end
    it 'recognises CA number' do
      expect(PhoneTools.country( ca_number )).to eq(:CA)
    end
    it 'recognises CH number' do
      expect(PhoneTools.country( ch_number )).to eq(:CH)
    end
    it 'recognises UK number' do
      expect(PhoneTools.country( uk_number )).to eq(:GB)
    end
    it 'recognises TT number' do
      expect(PhoneTools.country( tt_number )).to eq(:TT)
    end
    it 'recognises MY number' do
      expect(PhoneTools.country( my_number )).to eq(:MY)
    end
    it 'recognises AU number' do
      expect(PhoneTools.country( au_number )).to eq(:AU)
    end
    it 'recognises RU number' do
      expect(PhoneTools.country( ru_number )).to eq(:RU)
    end
    it 'recognises HK number' do
      expect(PhoneTools.country( hk_number )).to eq(:HK)
    end
  end
  
end
