shared_examples 'conversation pricer' do |alpha2, phone_number, expected_price|
  let(:expected_price_with_extra_message) { expected_price * 1.5 }

  let(:country)            { Country[alpha2] }
  let(:phone_number_model) { PhoneNumber.new number: phone_number }
  let(:phone_number_mini)  { MiniPhoneNumber.new phone_number }

  let(:draft_conversation) { build :conversation, :draft, customer_number: phone_number }
  let(:sent_conversation)  { build :conversation, :asked, customer_number: phone_number }
  let(:conversation_with_messages) { create :conversation, :with_stencil, :with_internal_number, :challenge_sent, :response_received, :reply_sent, :confirmed, :with_messages, customer_number: phone_number }
  let(:conversation_with_extra_message) do
    conversation_with_messages.tap do |cc|
      m = cc.messages.outbound.first
      m.segments = 2
      m.save!
    end
  end

  it 'prices alpha2' do
    expect(subject.price_for(alpha2)).to eq(expected_price)
  end

  it 'prices Country' do
    expect(subject.price_for(country)).to eq(expected_price)
  end

  it 'prices phone number as string' do
    expect(subject.price_for(phone_number)).to eq(expected_price)
  end

  it 'prices phone number as Model' do
    expect(subject.price_for(phone_number_model)).to eq(expected_price)
  end

  it 'prices phone number as Mini' do
    expect(subject.price_for(phone_number_mini)).to eq(expected_price)
  end

  it 'prices draft conversation' do
    expect(subject.price_for(draft_conversation)).to eq(0)
  end

  it 'prices sent conversation' do
    expect(subject.price_for(sent_conversation)).to eq(expected_price)
  end

  it 'prices conversation with messages' do
    expect(subject.price_for(conversation_with_messages)).to eq(expected_price)
  end

  it 'prices conversation with extra message' do
    expect(subject.price_for(conversation_with_extra_message)).to eq(expected_price_with_extra_message)
  end

end
