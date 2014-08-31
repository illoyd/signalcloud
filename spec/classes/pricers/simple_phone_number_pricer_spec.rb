require 'spec_helper'

fdescribe Pricers::SimplePhoneNumberPricer, :type => :model do
  let(:config) { Pricesheet.new({ US: 3, GB: 3, CA: 3, TT: 6, HK: 6, MY: 9, RU: '9' }) }
  subject      { described_class.new(config) }

  describe '#price_for' do
    
    context 'US' do
      include_examples 'phone number pricer', 'US', '+12151234567', BigDecimal.new('3')
    end
    
    context 'GB' do
      include_examples 'phone number pricer', 'GB', '+447540123456', BigDecimal.new('3')
    end
    
    context 'CA' do
      include_examples 'phone number pricer', 'CA', '+14161234567', BigDecimal.new('3')
    end
    
    context 'TT' do
      include_examples 'phone number pricer', 'TT', '+18681234567', BigDecimal.new('6')
    end
    
    context 'HK' do
      include_examples 'phone number pricer', 'HK', '+85212345678', BigDecimal.new('6')
    end
    
    context 'MY' do
      include_examples 'phone number pricer', 'MY', '+60123959999', BigDecimal.new('9')
    end
    
    context 'RU' do
      include_examples 'phone number pricer', 'RU', '+79111234567', BigDecimal.new('9')
    end

    context 'Australia' do
      let(:alpha2)             { 'AU' }
      let(:country)            { Country[alpha2] }
      let(:phone_number)       { '+61418123456' }
    
      let(:phone_number_model) { PhoneNumber.new number: phone_number }
      let(:phone_number_mini)  { MiniPhoneNumber.new phone_number }

      it 'fails to prices Country' do
        expect{subject.price_for(country)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'fails to prices alpha2' do
        expect{subject.price_for(alpha2)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'fails to prices phone number as string' do
        expect{subject.price_for(phone_number)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'fails to prices phone number as Model' do
        expect{subject.price_for(phone_number_model)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
      it 'fails to prices phone number as Mini' do
        expect{subject.price_for(phone_number_mini)}.to raise_error(SignalCloud::UnpriceableObjectError)
      end
  
    end
    
  end

end