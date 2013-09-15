describe 'PhoneTools' do

  describe ".normalize" do
    it { PhoneTools.normalize('+41 44 364 35 33').should == '41443643533' }
  end

  describe ".plausible?" do
    it { PhoneTools.plausible?('41 44 364 35 33').should be_true }
    it { PhoneTools.plausible?('+41 44 364 35 33').should be_true }
    it { PhoneTools.plausible?('+414436435 33').should be_true }
  end
  
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
      PhoneTools.country( us_number ).should == :US
    end
    it 'recognises CA number' do
      PhoneTools.country( ca_number ).should == :CA
    end
    it 'recognises CH number' do
      PhoneTools.country( ch_number ).should == :CH
    end
    it 'recognises UK number' do
      PhoneTools.country( uk_number ).should == :GB
    end
    it 'recognises TT number' do
      PhoneTools.country( tt_number ).should == :TT
    end
    it 'recognises MY number' do
      PhoneTools.country( my_number ).should == :MY
    end
    it 'recognises AU number' do
      PhoneTools.country( au_number ).should == :AU
    end
    it 'recognises RU number' do
      PhoneTools.country( ru_number ).should == :RU
    end
    it 'recognises HK number' do
      PhoneTools.country( hk_number ).should == :HK
    end
  end
  
end
