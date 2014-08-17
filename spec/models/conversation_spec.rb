# encoding: UTF-8
require 'spec_helper'

describe Conversation, :type => :model do

  shared_examples 'sends message' do |method|
    it 'does not raise error' do
      expect{ subject.send(method) }.not_to raise_error
    end
    it 'creates a new message' do
      expect{ subject.send(method) }.to change{subject.messages(true).count}.by(1)
    end
    it 'assigns body' do
      subject.send(method)
      msg = subject.messages(true).last
      expect(msg.body).to eq(expected_body)
    end
    it 'assigns to_number' do
      subject.send(method)
      msg = subject.messages(true).last
      expect(msg.to_number).to eq(subject.customer_number)
    end
    it 'assigns from_number' do
      subject.send(method)
      msg = subject.messages(true).last
      expect(msg.from_number).to eq(subject.internal_number)
    end
    it 'can get communication gateway' do
      subject.send(method)
      msg = subject.messages(true).last
      expect{ msg.conversation.communication_gateway }.not_to raise_error
    end
  end
  
  shared_examples 'accepts answer' do |answer|
    it 'does not raise error' do
      expect{ subject.accept_answer!(answer) }.not_to raise_error
    end
    it 'creates a new message' do
      expect{ subject.accept_answer!(answer) }.to change{subject.messages(true).count}.by(1)
    end
    it 'assigns body' do
      subject.accept_answer!(answer)
      msg = subject.messages(true).last
      expect(msg.body).to eq(expected_body)
    end
    it 'assigns to_number' do
      subject.accept_answer!(answer)
      msg = subject.messages(true).last
      expect(msg.to_number).to eq(subject.customer_number)
    end
    it 'assigns from_number' do
      subject.accept_answer!(answer)
      msg = subject.messages(true).last
      expect(msg.from_number).to eq(subject.internal_number)
    end
    it 'can get communication gateway' do
      subject.accept_answer!(answer)
      msg = subject.messages(true).last
      expect{ msg.conversation.communication_gateway }.not_to raise_error
    end
  end

  describe 'validations' do  
    it { is_expected.to belong_to :stencil }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_one  :ledger_entry }

    [:stencil, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :expires_at].each do |attribute| 
      it { is_expected.to validate_presence_of(attribute) }
    end
  end
  
  describe 'callbacks' do
    subject { build :conversation }
    it 'creates a ledger entry' do
      expect{ subject.save }.to change{subject.ledger_entry}.from(nil)
    end
  end

  describe '#is_open? and #is_closed? and #has_errored?' do
    [ :asking, :asked ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, workflow_state: status }

        describe '#is_open?' do
          subject { super().is_open? }
          it { is_expected.to be_truthy }
        end

        describe '#is_closed?' do
          subject { super().is_closed? }
          it { is_expected.to be_falsey }
        end

        describe '#errored?' do
          subject { super().errored? }
          it { is_expected.to be_falsey }
        end
      end
    end
    
    [ :draft, :receiving, :received, :confirming, :confirmed, :denying, :denied, :failing, :failed, :expiring, :expired ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, workflow_state: status }

        describe '#is_open?' do
          subject { super().is_open? }
          it { is_expected.to be_falsey }
        end

        describe '#is_closed?' do
          subject { super().is_closed? }
          it { is_expected.to be_truthy }
        end

        describe '#errored?' do
          subject { super().errored? }
          it { is_expected.to be_falsey }
        end
      end
    end
    
    [ :errored ].each do |status|
    #[ Conversation::ERROR_INVALID_TO, Conversation::ERROR_INVALID_FROM, Conversation::ERROR_BLACKLISTED_TO, Conversation::ERROR_NOT_SMS_CAPABLE, Conversation::ERROR_CANNOT_ROUTE, Conversation::ERROR_SMS_QUEUE_FULL ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, workflow_state: status }

        describe '#is_open?' do
          subject { super().is_open? }
          it { is_expected.to be_falsey }
        end

        describe '#is_closed?' do
          subject { super().is_closed? }
          it { is_expected.to be_truthy }
        end

        describe '#errored?' do
          subject { super().errored? }
          it { is_expected.to be_truthy }
        end
      end
    end
  end
  
  describe "#has_challenge_been_sent?" do
    context 'when challenge not sent' do
      subject { build :conversation }

      describe '#has_challenge_been_sent?' do
        subject { super().has_challenge_been_sent? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when challenge sent' do
      subject { build :conversation, :challenge_sent }

      describe '#has_challenge_been_sent?' do
        subject { super().has_challenge_been_sent? }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe "#has_response_been_received?" do
    context 'when response has not been received' do
      subject { build :conversation }

      describe '#has_response_been_received?' do
        subject { super().has_response_been_received? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when response has been received' do
      subject { build :conversation, :response_received }

      describe '#has_response_been_received?' do
        subject { super().has_response_been_received? }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe "#has_reply_been_sent?" do
    context 'when reply not sent' do
      subject { build :conversation }

      describe '#has_reply_been_sent?' do
        subject { super().has_reply_been_sent? }
        it { is_expected.to be_falsey }
      end
    end
    context 'when reply sent' do
      subject { build :conversation, :reply_sent }

      describe '#has_reply_been_sent?' do
        subject { super().has_reply_been_sent? }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe "#update_expiry_time_based_on_seconds_to_live" do
    let(:seconds_to_live) { 360 }
    let(:original_expiry) { 60.seconds.ago }
    subject { build :conversation, expires_at: nil }

    it "overrides existing expires_at" do
      subject.expires_at = original_expiry
      subject.seconds_to_live = seconds_to_live
      expect { subject.update_expiry_time_based_on_seconds_to_live }.to change{subject.expires_at}.from(original_expiry)
      expect(subject.expires_at).to be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expires_at manually" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.update_expiry_time_based_on_seconds_to_live }.to change{subject.expires_at}.from(nil)
      expect(subject.expires_at).to be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expires_at on save" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.save }.to change{subject.expires_at}.from(nil)
      expect(subject.expires_at).to be_within(0.5).of( seconds_to_live.seconds.from_now )
    end
  end
  
  describe '#compare_answer' do
    let(:positive) { 'yes' }
    let(:negative) { 'no' }
    let(:failed) { 'walrus' }
    subject { build(:conversation, expected_confirmed_answer: positive, expected_denied_answer: negative) }

    it 'recognises positive answer' do
      expect(subject.compare_answer( positive )).to eq(:confirmed)
    end

    it 'recognises uppercase positive answer' do
      expect(subject.compare_answer( positive.upcase )).to eq(:confirmed)
    end

    it 'recognises padded positive answer' do
      expect(subject.compare_answer( "   #{positive}   " )).to eq(:confirmed)
    end

    it 'recognises negative answer' do
      expect(subject.compare_answer( negative )).to eq(:denied)
    end
    
    it 'recognises uppercase negative answer' do
      expect(subject.compare_answer( negative.upcase )).to eq(:denied)
    end
    
    it 'recognises padded negative answer' do
      expect(subject.compare_answer( "   #{negative}   " )).to eq(:denied)
    end
    
    it 'ignores invalid answer' do
      expect(subject.compare_answer( failed )).to eq(:failed)
    end
    
    it 'ignores uppercase invalid answer' do
      expect(subject.compare_answer( failed.upcase )).to eq(:failed)
    end
    
    it 'ignores padded invalid answer' do
      expect(subject.compare_answer( "   #{failed}   " )).to eq(:failed)
    end

  end
  
  describe '#answer_applies?' do
    let(:positive) { 'yes' }
    let(:negative) { 'no' }
    let(:failed) { 'walrus' }
    subject { build(:conversation, expected_confirmed_answer: positive, expected_denied_answer: negative) }

    it 'recognises positive answer' do
      expect(subject.answer_applies?( positive )).to be_truthy
    end

    it 'recognises uppercase positive answer' do
      expect(subject.answer_applies?( positive.upcase )).to be_truthy
    end

    it 'recognises padded positive answer' do
      expect(subject.answer_applies?( "   #{positive}   " )).to be_truthy
    end

    it 'recognises negative answer' do
      expect(subject.answer_applies?( negative )).to be_truthy
    end
    
    it 'recognises uppercase negative answer' do
      expect(subject.answer_applies?( negative.upcase )).to be_truthy
    end
    
    it 'recognises padded negative answer' do
      expect(subject.answer_applies?( "   #{negative}   " )).to be_truthy
    end
    
    it 'ignores invalid answer' do
      expect(subject.answer_applies?( failed )).to be_falsey
    end
    
    it 'ignores uppercase invalid answer' do
      expect(subject.answer_applies?( failed.upcase )).to be_falsey
    end
    
    it 'ignores padded invalid answer' do
      expect(subject.answer_applies?( "   #{failed}   " )).to be_falsey
    end
    
  end
  
  describe '#accept_answer!' do
    let(:organization)     { create :organization, :test_twilio }
    let(:comm_gateway)     { organization.communication_gateways.first }
    let(:phone_number)     { create :phone_number, organization: organization, communication_gateway: comm_gateway }
    let(:phone_book)       { create :phone_book, organization: organization }
    let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
    let(:stencil)          { create :stencil, organization: organization, phone_book: phone_book }
    before(:each)          { phone_book_entry }
    let(:exp_confirmed)    { 'yes' }
    let(:exp_denied)       { 'no' }
    subject { create(:conversation, :challenge_sent, :response_received, expected_confirmed_answer: exp_confirmed, expected_denied_answer: exp_denied, stencil: stencil, internal_number: phone_number.number) }
    
    context 'when given a confirmed answer' do
      let(:expected_body) { subject.confirmed_reply }
      it 'changes state to confirming' do
        expect{ subject.accept_answer!( subject.expected_confirmed_answer ) }.to change( subject, :workflow_state ).to( 'confirming' )
      end
      include_examples 'accepts answer', 'yes'
    end
    
    context 'when given a denied answer' do
      let(:expected_body) { subject.denied_reply }
      it 'changes state to denying' do
        expect{ subject.accept_answer!( subject.expected_denied_answer ) }.to change( subject, :workflow_state ).to( 'denying' )
      end
      include_examples 'accepts answer', 'no'
    end
    
    context 'when given a failing answer' do
      let(:expected_body) { subject.failed_reply }
      it 'changes state to failing' do
        expect{ subject.accept_answer!( 'ostriches!' ) }.to change( subject, :workflow_state ).to( 'failing' )
      end
      include_examples 'accepts answer', 'ostriches!'
    end
  end
  
  describe '#assign_internal_number' do
    let(:organization)     { create :organization, :test_twilio }
    let(:comm_gateway)     { organization.communication_gateways.first }
    let(:phone_number)     { create :phone_number, organization: organization, communication_gateway: comm_gateway }
    let(:phone_book)       { create :phone_book, organization: organization }
    let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
    let(:stencil)          { create :stencil, organization: organization, phone_book: phone_book }
    before(:each)          { phone_book_entry }
    subject { build :conversation, stencil: stencil, internal_number: nil }

    it 'does not error' do
      expect{ subject.send(:assign_internal_number) }.not_to raise_error
    end
    it 'sets the from number' do
      expect{ subject.send(:assign_internal_number) }.to change(subject, :internal_number).to( phone_number.number )
    end
    it 'does not change the from number' do
      subject.internal_number = Twilio::VALID_NUMBER
      expect{ subject.send(:assign_internal_number) }.not_to change(subject, :internal_number).from( Twilio::VALID_NUMBER )
    end
  end
  
  describe '#communication_gateway' do
    let(:organization)     { create :organization, :test_twilio }
    let(:comm_gateway)     { organization.communication_gateways.first }
    let(:phone_number)     { create :phone_number, organization: organization, communication_gateway: comm_gateway }
    let(:phone_book)       { create :phone_book, organization: organization }
    let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
    let(:stencil)          { create :stencil, organization: organization, phone_book: phone_book }
    before(:each)          { phone_book_entry }
    subject { create :conversation, stencil: stencil, internal_number: phone_number.number }
    
    describe '#internal_number' do
      subject { super().internal_number }
      it { is_expected.to eq(phone_number.number) }
    end
    it 'does not error' do
      expect{ subject.communication_gateway }.not_to raise_error
    end
  end
  
  context 'with full org' do
    let(:organization)     { create :organization, :test_twilio }
    let(:phone_number)     { create :phone_number, organization: organization, communication_gateway: organization.communication_gateways.first }
    let(:phone_book)       { create :phone_book, organization: organization }
    let(:phone_book_entry) { create :phone_book_entry, phone_book: phone_book, phone_number: phone_number }
    let(:stencil)          { create :stencil, organization: organization, phone_book: phone_book }
    before(:each)          { phone_book_entry }
    
    describe '#ask!' do
      let(:expected_body) { subject.question }
      subject { create(:conversation, stencil: stencil, internal_number: phone_number.number) }

      describe '#can_ask?' do
        subject { super().can_ask? }
        it { is_expected.to be_truthy }
      end
      include_examples 'sends message', :ask!
    end
    
    describe '#asked!' do
      subject { create(:conversation, workflow_state: :asking, stencil: stencil, internal_number: phone_number.number) }
      it 'updates challenge_sent_at' do
        expect{ subject.asked! }.to change( subject, :challenge_sent_at )
      end
    end
  
    describe '#confirm!' do
      let(:expected_body) { subject.confirmed_reply }
      subject { create(:conversation, :challenge_sent, :response_received, stencil: stencil, internal_number: phone_number.number) }

      describe '#can_confirm?' do
        subject { super().can_confirm? }
        it { is_expected.to be_truthy }
      end
      include_examples 'sends message', :confirm!
    end
  
    describe '#confirmed!' do
      subject { create(:conversation, :challenge_sent, :response_received, workflow_state: :confirming, stencil: stencil, internal_number: phone_number.number) }
      it 'updates reply_sent_at' do
        expect{ subject.confirmed! }.to change( subject, :reply_sent_at )
      end
    end
  
    describe '#deny!' do
      let(:expected_body) { subject.denied_reply }
      subject { create(:conversation, :challenge_sent, :response_received, stencil: stencil, internal_number: phone_number.number) }

      describe '#can_deny?' do
        subject { super().can_deny? }
        it { is_expected.to be_truthy }
      end
      include_examples 'sends message', :deny!
    end
  
    describe '#denied!' do
      subject { create(:conversation, :challenge_sent, :response_received, workflow_state: :denying, stencil: stencil, internal_number: phone_number.number) }
      it 'updates reply_sent_at' do
        expect{ subject.denied! }.to change( subject, :reply_sent_at )
      end
    end
  
    describe '#fail!' do
      let(:expected_body) { subject.failed_reply }
      subject { create(:conversation, :challenge_sent, :response_received, stencil: stencil, internal_number: phone_number.number) }

      describe '#can_fail?' do
        subject { super().can_fail? }
        it { is_expected.to be_truthy }
      end
      include_examples 'sends message', :fail!
    end
  
    describe '#failed!' do
      subject { create(:conversation, :challenge_sent, :response_received, workflow_state: :failing, stencil: stencil, internal_number: phone_number.number) }
      it 'updates reply_sent_at' do
        expect{ subject.failed! }.to change( subject, :reply_sent_at )
      end
    end
  
    describe '#expire!' do
      let(:expected_body) { subject.expired_reply }
      subject { create(:conversation, :challenge_sent, stencil: stencil, internal_number: phone_number.number) }

      describe '#can_expire?' do
        subject { super().can_expire? }
        it { is_expected.to be_truthy }
      end
      include_examples 'sends message', :expire!
    end

    describe '#expired!' do
      subject { create(:conversation, :challenge_sent, workflow_state: :expiring, stencil: stencil, internal_number: phone_number.number) }
      it 'updates reply_sent_at' do
        expect{ subject.expired! }.to change( subject, :reply_sent_at )
      end
    end
  
  end

end
