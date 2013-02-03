describe 'PhoneTools' do

  describe "#normalize" do
    it { PhoneTools.normalize('+41 44 364 35 33').should == '41443643533' }
  end

  describe "#plausible?" do
    it { PhoneTools.plausible?('41 44 364 35 33').should be_true }
    it { PhoneTools.plausible?('+41 44 364 35 33').should be_true }
    it { PhoneTools.plausible?('+414436435 33').should be_true }
  end
  
  describe '#united_states?' do
    it { PhoneTools.united_states?('41 44 364 35 33').should be_false }
    it { PhoneTools.united_states?('12151234567').should be_true }
    it { PhoneTools.united_states?('14161234567').should be_false }
    it { PhoneTools.united_states?('18681234567').should be_false }
  end

  describe '#canadian?' do
    it { PhoneTools.canadian?('41 44 364 35 33').should be_false }
    it { PhoneTools.canadian?('12151234567').should be_false }
    it { PhoneTools.canadian?('14161234567').should be_true }
    it { PhoneTools.canadian?('18681234567').should be_false }
  end

  describe '#other_nanp_country?' do
    it { PhoneTools.other_nanp_country?('41 44 364 35 33').should be_false }
    it { PhoneTools.other_nanp_country?('12151234567').should be_false }
    it { PhoneTools.other_nanp_country?('14161234567').should be_false }
    it { PhoneTools.other_nanp_country?('18681234567').should be_true }
  end

end
