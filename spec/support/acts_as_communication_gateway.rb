shared_examples 'a communication gateway' do |factory|

  describe 'workflow' do
    it { is_expected.to respond_to(:new?).with(0).arguments }
    it { is_expected.to respond_to(:ready?).with(0).arguments }
    it { is_expected.to respond_to(:create_remote!).with(0).arguments }
    it { is_expected.to respond_to(:update_remote!).with(0).arguments }
  end

  describe 'phone number interface' do
    it { is_expected.to respond_to(:phone_number).with(1).argument }
    it { is_expected.to respond_to(:purchase_phone_number!).with(1).argument }
    it { is_expected.to respond_to(:unpurchase_phone_number!).with(1).argument }
  end
  
  describe 'message interface' do
    it { is_expected.to respond_to(:message).with(1).argument }
    it { is_expected.to respond_to(:send_message!).with(3).arguments }
  end

end