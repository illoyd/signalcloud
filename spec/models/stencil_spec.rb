require 'spec_helper'

shared_examples_for 'a conversation builder' do
  it 'creates a new conversation' do
    expect(subject.build_conversation(payload)).to be_a_new Conversation
  end
  
  it 'assigns the customer number' do
    expect(subject.build_conversation(payload).customer_number).to eq(customer)
  end
  
  it 'assigns the internal number' do
    expect(subject.build_conversation(payload).internal_number.number).to eq(internal)
  end
  
  it 'assigns the internal number' do
    expect(subject.build_conversation(payload).internal_number).to eq(phone_number)
  end
  
  Stencil::CONVERSATION_PARAMETERS.each do |attribute|
    it "assigns #{ attribute }" do
      expect(subject.build_conversation(payload).send(attribute)).to eq(subject.send(attribute))
    end
  end
end

describe Stencil, :type => :model do
  let(:organization)     { create :organization, :with_mock_comms }
  let(:phone_book)       { create :phone_book, organization: organization }
  let(:phone_number)     { create :phone_number, organization: organization, communication_gateway: organization.communication_gateway_for(:mock) }

  context 'with fully defined stencil' do
    subject              { build :stencil, organization: organization, phone_book: phone_book }
  
    context 'using explicit internal number' do 
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer, internal_number_id: phone_number.id} }
      
      it_behaves_like 'a conversation builder'

      it 'creates a valid conversation' do
        expect(subject.build_conversation(payload)).to be_valid
      end
    end
    
    context 'using implicit phone book' do
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer} }
      before(:each)      { phone_book.phone_book_entries.create(phone_number: phone_number) }

      it_behaves_like 'a conversation builder'

      it 'creates a valid conversation' do
        expect(subject.build_conversation(payload)).to be_valid
      end
    end
  end
  
  context 'with partially defined stencil' do
    subject              { build :stencil, organization: organization, phone_book: phone_book, question: nil }

    context 'using explicit internal number' do 
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer, internal_number_id: phone_number.id} }
      
      it_behaves_like 'a conversation builder'

      it 'creates an invalid conversation' do
        expect(subject.build_conversation(payload)).not_to be_valid
      end
    end
    
    context 'using implicit phone book' do
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer} }
      before(:each)      { phone_book.phone_book_entries.create(phone_number: phone_number) }
  
      it_behaves_like 'a conversation builder'

      it 'creates an invalid conversation' do
        expect(subject.build_conversation(payload)).not_to be_valid
      end
    end
  end
  
  context 'validations' do
    it 'accepts a valid HTTP URI' do
      expect( build :stencil, webhook_uri: 'http://www.google.com' ).to be_valid
    end
    it 'accepts a valid HTTPS URI' do
      expect( build :stencil, webhook_uri: 'https://www.ft.com' ).to be_valid
    end
    it 'is invalid when invalid URI' do
      expect( build :stencil, webhook_uri: 'abcd1234' ).not_to be_valid
    end
    it 'is invalid when IP' do
      expect( build :stencil, webhook_uri: '192.168.1.1' ).not_to be_valid
    end
    it 'is invalid when non-HTTP URI' do
      expect( build :stencil, webhook_uri: 'git://github.com' ).not_to be_valid
    end
  end

end
