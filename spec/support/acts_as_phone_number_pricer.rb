shared_examples 'phone number pricer' do |alpha2, phone_number, expected_price|
  let(:country)            { Country[alpha2] }
  let(:phone_number_model) { PhoneNumber.new number: phone_number }
  let(:phone_number_mini)  { MiniPhoneNumber.new phone_number }

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

end
