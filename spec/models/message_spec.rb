# encoding: UTF-8
require 'spec_helper'

describe Message do
  fixtures :accounts, :appliances, :tickets, :messages
  
  # Validations
  [ :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid ].each do |attribute| 
    it { should allow_mass_assignment_of attribute }
  end
  it { should belong_to(:ticket) }
  it { should have_one(:ledger_entry) }
  it { should validate_presence_of(:ticket_id) }
  it { should ensure_length_of(:twilio_sid).is_equal_to(Twilio::SID_LENGTH) }
  it { should validate_numericality_of(:our_cost) }
  it { should validate_numericality_of(:provider_cost) }
  it { should validate_uniqueness_of(:twilio_sid) }
  
  def random_sms_string(length)
    charset_length = Message::SMS_CHARSET_LIST.length
    (1..length).map{ Message::SMS_CHARSET_LIST[rand(charset_length)] }.join('')
  end
  
  def random_unicode_string(length)
    charset_length = Message::SMS_CHARSET_LIST.length
    str = (1..length).map{ (rand(111411)+1).chr(Encoding::UTF_8) }.join('')
    str.ascii_only? ? random_unicode_string(length) : str
  end
  
  describe '.is_sms_charset?' do
    context 'when in SMS charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "recognises #{length}-sized message" do
          Message.is_sms_charset?(random_sms_string(length)).should be_true
        end
      end
    end
    context 'when using unicode charset' do
      [ 1, 8, 65, 150, 500 ].each do |length|
        it "does not recognise #{length}-sized message" do
          str = random_unicode_string(length)
          #puts str
          Message.is_sms_charset?(str).should be_false
        end
      end
    end
  end

  describe '#is_challenge? and #is_reply?' do
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
  end
  
end
