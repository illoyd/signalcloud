require 'spec_helper'

shared_examples_for 'a conversation builder' do
  it 'creates a new conversation' do
    expect(subject.build_conversation(payload)).to be_a_new Conversation
  end
  
  it 'assigns the customer number' do
    expect(subject.build_conversation(payload).customer_number).to eq(customer)
  end
  
  it 'assigns the internal number' do
    expect(subject.build_conversation(payload).internal_number).to eq(internal)
  end
  
  Stencil::CONVERSATION_PARAMETERS.each do |attribute|
    it "assigns #{ attribute }" do
      expect(subject.build_conversation(payload).send(attribute)).to eq(subject.send(attribute))
    end
  end
end

describe Stencil, :type => :model do
  let(:organization)     { build :organization, :with_mock_communication_gateway }
  let(:phone_book)       { build :phone_book, organization: organization }

  context 'with fully defined stencil' do
    subject              { build :stencil, organization: organization, phone_book: phone_book }
  
    context 'using explicit internal number' do 
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:internal)     { Twilio::INVALID_NUMBER }
      let(:payload)      { {customer_number: customer, internal_number: internal} }
      
      it_behaves_like 'a conversation builder'

      it 'creates a valid conversation' do
        expect(subject.build_conversation(payload)).to be_valid
      end
    end
    
    context 'using implicit phone book' do
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:phone_number) { create :phone_number, organization: organization }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer} }
      before(:each)      { phone_book.save; phone_book.phone_book_entries.create(phone_number: phone_number) }

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
      let(:internal)     { Twilio::INVALID_NUMBER }
      let(:payload)      { {customer_number: customer, internal_number: internal} }
      
      it_behaves_like 'a conversation builder'

      it 'creates an invalid conversation' do
        expect(subject.build_conversation(payload)).not_to be_valid
      end
    end
    
    context 'using implicit phone book' do
      let(:customer)     { Twilio::VALID_NUMBER }
      let(:phone_number) { create :phone_number, organization: organization }
      let(:internal)     { phone_number.number }
      let(:payload)      { {customer_number: customer} }
      before(:each)      { phone_book.save; phone_book.phone_book_entries.create(phone_number: phone_number) }
  
      it_behaves_like 'a conversation builder'

      it 'creates an invalid conversation' do
        expect(subject.build_conversation(payload)).not_to be_valid
      end
    end
  end

end
