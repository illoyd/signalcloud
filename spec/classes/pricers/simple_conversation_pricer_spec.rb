require 'spec_helper'

fdescribe Pricers::SimpleConversationPricer, :type => :model do
  let(:us_number) { '+12151234567' }
  let(:gb_number) { '+447540123456' }
  let(:ca_number) { '+14161234567' }

  let(:tt_number) { '+18681234567' }
  let(:hk_number) { '+85212345678' }

  let(:my_number) { '+60123959999' }
  let(:ru_number) { '+79111234567' }

  let(:au_number) { '+61418123456' }

  let(:config) { Pricesheet.new({ US: '0.1', GB: '0.1', CA: '0.1', TT: '0.2', HK: '0.2', MY: '0.3', RU: '0.3' }) }
  subject      { described_class.new(config) }

  describe '#price_for' do
    context 'US' do
      include_examples 'conversation pricer', 'US', '+12151234567', BigDecimal.new('0.1')
    end
    
    context 'GB' do
      include_examples 'conversation pricer', 'GB', '+447540123456', BigDecimal.new('0.1')
    end
    
    context 'CA' do
      include_examples 'conversation pricer', 'CA', '+14161234567', BigDecimal.new('0.1')
    end
    
    context 'TT' do
      include_examples 'conversation pricer', 'TT', '+18681234567', BigDecimal.new('0.2')
    end
    
    context 'HK' do
      include_examples 'conversation pricer', 'HK', '+85212345678', BigDecimal.new('0.2')
    end
    
    context 'MY' do
      include_examples 'conversation pricer', 'MY', '+60123959999', BigDecimal.new('0.3')
    end
    
    context 'RU' do
      include_examples 'conversation pricer', 'RU', '+79111234567', BigDecimal.new('0.3')
    end
    
    context 'Australia' do
      let(:country)      { 'AU' }
      let(:phone_number) { '+61418123456' }
    
      let(:phone_number_model) { PhoneNumber.new number: phone_number }
      let(:phone_number_mini)  { MiniPhoneNumber.new phone_number }
      let(:sent_conversation)       { build :conversation, :challenge_sent, customer_number: phone_number }

      it 'prices Country' do
        expect{subject.price_for(Country[country])}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'prices alpha2' do
        expect{subject.price_for(country)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'prices phone number as string' do
        expect{subject.price_for(phone_number)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'prices phone number as Model' do
        expect{subject.price_for(phone_number_model)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'prices phone number as Mini' do
        expect{subject.price_for(phone_number_mini)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'prices sent conversation' do
        expect{subject.price_for(sent_conversation)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
    end
    
  end

end