require 'spec_helper'
describe ConversationPricer do
  it_behaves_like 'a pricer'
  
  describe '#price_for' do
    let(:us_price_sheet)  { PriceSheet.new 'us', 0.10, 1.5 }
    let(:gb_price_sheet)  { PriceSheet.new 'gb', 0.15, 2.0 }
    before(:each) do
      subject.price_sheet_library.memoize(us_price_sheet)
      subject.price_sheet_library.memoize(gb_price_sheet)
    end
    
    context 'with conversation with US customer' do
#       let(:organization)     { build_stubbed :organization, :test_twilio }
#       let(:phone_number)     { build_stubbed :phone_number, organization: organization, communication_gateway: organization.communication_gateways.first }
#       let(:phone_book)       { create :phone_book, organization: organization }
#       let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
#       let(:stencil)          { build_stubbed :stencil, organization: organization, phone_book: phone_book }
      let(:phone_number) { build_stubbed :us_phone_number }
      let(:conversation) { build_stubbed :conversation, :asked, customer_number: phone_number.number }
      
      it 'returns a BigDecimal' do
        subject.price_for(conversation).should be_a BigDecimal
      end
      
      [ :draft, :asking, :asked, :receiving, :received, :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired ].each do |state|
        context "with #{state} conversation" do
          let(:conversation) { create :conversation, state, :with_messages, customer_number: phone_number.number }
          it 'calculates price' do
            subject.price_for( conversation ).should == us_price_sheet.base_conversation_price
          end
        end
      end
      
      [ :asking, :asked, :receiving, :received, :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired ].each do |state|
        context "with long challenge #{state} conversation" do
          let(:conversation) { create :conversation, state, :with_messages, customer_number: phone_number.number, question: 'q'*170 }
          it 'calculates price' do
            subject.price_for( conversation ).should == ( us_price_sheet.base_conversation_price * 1.5 )
          end
        end
      end
      
      [ :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired ].each do |state|
        context "with long reply #{state} conversation" do
          let(:conversation) { create :conversation, state, :with_messages, customer_number: phone_number.number, confirmed_reply: 'c'*170, denied_reply: 'd'*170, failed_reply: 'f'*170, expired_reply: 'e'*170 }
          it 'calculates price' do
            subject.price_for( conversation ).should == ( us_price_sheet.base_conversation_price * 1.5 )
          end
        end
      end
      
      [ :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired ].each do |state|
        context "with long challenge and reply #{state} conversation" do
          let(:conversation) { create :conversation, state, :with_messages, customer_number: phone_number.number, question: 'q'*170, confirmed_reply: 'c'*170, denied_reply: 'd'*170, failed_reply: 'f'*170, expired_reply: 'e'*170 }
          it 'calculates price' do
            subject.price_for( conversation ).should == ( us_price_sheet.base_conversation_price * 2.0 )
          end
        end
      end
      
    end

    context 'with conversation with GB customer' do
    end

  end #price_for

end
