require 'spec_helper'

describe Message do
  fixtures :accounts, :appliances, :tickets, :messages
  
  # Validations
  it { [ :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid ].each { |param| should allow_mass_assignment_of(param) } }
  it { should belong_to(:ticket) }
  it { should have_one(:ledger_entry) }
  it { should validate_presence_of(:ticket_id) }
  it { should ensure_length_of(:twilio_sid).is_equal_to(Twilio::SID_LENGTH) }
  it { should validate_numericality_of(:our_cost) }
  it { should validate_numericality_of(:provider_cost) }
  it { should validate_uniqueness_of(:twilio_sid) }
  
  describe '#is_challenge?' do
    context 'when challenge message' do
      subject { create :challenge_message }
      its(:'is_challenge?') { should be_true }
      its(:'is_reply?') { should be_false }
    end
    context 'when reply message' do
      subject { create :reply_message }
      its(:'is_challenge?') { should be_false }
      its(:'is_reply?') { should be_true }
    end
    context 'when neither challenge nor reply message' do
      subject { create :message, message_kind: nil }
      its(:'is_challenge?') { should be_false }
      its(:'is_reply?') { should be_false }
    end
  end

  describe "#payload" do
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
      message.payload.should eq( expected_payload )
    end
  end
  
  describe "#cached_payload" do
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
      message.cached_payload.should eq( message.payload )
      message.cached_payload.should eq( expected_payload )
    end
  end
  
  describe '#ledger_entry' do
    it 'should auto-save ledger entry' do
      message = Message.new( payload: { body: 'Hello!', to: '+12121234567', from: '+4561237890' }, twilio_sid: 'XX' + SecureRandom.hex(16) )
      message.ticket = tickets(:test_ticket)
      message.account.should_not be_nil
      #expect{ message.save! }.to_not raise_error
      
      ledger_entry = message.build_ledger_entry( narrative: 'TEST' )
      #ledger_entry.item = message
      expect{ message.save! }.to_not raise_error
      
      ledger_entry.item_id.should eq( message.id )
      ledger_entry.item_type.should eq( message.class.name.to_s )
      ledger_entry.item.should eq( message )

      #ledger_entry.item.respond_to?(:account).should == true
      #ledger_entry.item.should_not be_nil

      expect{ ledger_entry.ensure_account }.to_not raise_error      
      ledger_entry.account_id.should eq( message.account.id )
      
      expect{ message.save! }.to_not raise_error
    end
  end
  
  describe "payload helpers" do
    let(:expected_payload) { { body: 'Hello!', to: '+12121234567', from: '+4561237890', direction: 'api-in' }.with_indifferent_access }
    subject { create :message, payload: expected_payload }
    its(:body) { should == expected_payload[:body] }
    its(:to_number) { should == expected_payload[:to] }
    its(:from_number) { should == expected_payload[:from] }
    its(:direction) { should == expected_payload[:direction] }
#     it "should return payload components" do
#       # Prepare an expected payload
#       expected_payload = { body: 'Hello!', to: '+12121234567', from: '+4561237890' }.with_indifferent_access
#       
#       # Create a new message and test 
#       message = Message.new( payload: expected_payload )
#       
#       # Test each payload helper
#       message.body.should == expected_payload[:body]
#       message.to_number.should == expected_payload[:to]
#       message.from_number.should == expected_payload[:from]
#     end
  end
  
end
