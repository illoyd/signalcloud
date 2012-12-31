require 'spec_helper'

describe Message do
  fixtures :tickets, :messages
  
  # Validations
  it { [ :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid ].each { |param| should allow_mass_assignment_of(param) } }
  it { should belong_to(:ticket) }
  it { should validate_presence_of(:ticket_id) }
  it { should ensure_length_of(:twilio_sid).is_equal_to(Twilio::SID_LENGTH) }
  it { should validate_numericality_of(:our_cost) }
  it { should validate_numericality_of(:provider_cost) }
  it { should validate_uniqueness_of(:twilio_sid) }

  describe ".payload" do
    it "should encrypt and decrypt nicely" do
      # Prepare an expected payload
      expected_payload = { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access
      
      # Next, create a new message - both 'payload' and 'encrypted payload' should be nil
      message = Message.new()
      message.encrypted_payload.should be_nil
      message.payload.should be_nil
      
      # Add the payload, then re-try - they should not be nil
      message.payload = expected_payload
      message.encrypted_payload.should_not be_nil
      message.payload.should_not be_nil
      
      # Finally, is the stored payload the same as the expected payload?
      expect( message.payload ).to eq( expected_payload )
    end
  end
  
  describe ".cached_payload" do
    it "should encrypt and decrypt nicely" do
      # Prepare an expected payload
      expected_payload = { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access
      
      # Next, create a new message without a payload; the cache should be nil
      message = Message.new()
      message.cached_payload.should be_nil
      
      # Add the payload, then re-try - they should not be nil
      message.payload = expected_payload
      message.cached_payload.should_not be_nil

      # Ensure that payload is equal to its cache
      expect( message.cached_payload ).to eq( message.payload )
      expect( message.cached_payload ).to eq( expected_payload )
    end
  end
  
  describe "payload helpers" do
    it "should return payload components" do
      # Prepare an expected payload
      expected_payload = { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access
      
      # Create a new message and test 
      message = Message.new( payload: expected_payload )
      
      # Test each payload helper
      message.body.should == expected_payload[:body]
      message.to_number.should == expected_payload[:to]
      message.from_number.should == expected_payload[:from]
    end
  end
  
end
