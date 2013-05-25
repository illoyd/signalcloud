# encoding: UTF-8
require 'spec_helper'

describe Conversation do

  describe 'validations' do  
    it { should belong_to :stencil }
    it { should have_many :messages }

    [ :seconds_to_live, :stencil, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at ].each do |attribute| 
      it { should allow_mass_assignment_of(attribute) }
    end

    [:stencil, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end
  end
  
  describe '#is_open? and #is_closed? and #has_errored?' do
    [ Conversation::QUEUED, Conversation::CHALLENGE_SENT ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, status: status }
        its('is_open?') { should be_true }
        its('is_closed?') { should be_false }
        its('has_errored?') { should be_false }
      end
    end
    
    [ Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, status: status }
        its('is_open?') { should be_false }
        its('is_closed?') { should be_true }
        its('has_errored?') { should be_false }
      end
    end
    
    [ Conversation::ERROR_INVALID_TO, Conversation::ERROR_INVALID_FROM, Conversation::ERROR_BLACKLISTED_TO, Conversation::ERROR_NOT_SMS_CAPABLE, Conversation::ERROR_CANNOT_ROUTE, Conversation::ERROR_SMS_QUEUE_FULL ].each do |status|
      context "when status is #{status}" do
        subject { build :conversation, status: status }
        its('is_open?') { should be_false }
        its('is_closed?') { should be_true }
        its('has_errored?') { should be_true }
      end
    end
  end
  
  describe "#has_challenge_been_sent?" do
    context 'when challenge not sent' do
      subject { build :conversation }
      its('has_challenge_been_sent?') { should be_false }
    end
    context 'when challenge sent' do
      subject { build :conversation, :challenge_sent }
      its('has_challenge_been_sent?') { should be_true }
    end
  end

  describe "#has_response_been_received?" do
    context 'when response has not been received' do
      subject { build :conversation }
      its('has_response_been_received?') { should be_false }
    end
    context 'when response has been received' do
      subject { build :conversation, :response_received }
      its('has_response_been_received?') { should be_true }
    end
  end

  describe "#has_reply_been_sent?" do
    context 'when reply not sent' do
      subject { build :conversation }
      its('has_reply_been_sent?') { should be_false }
    end
    context 'when reply sent' do
      subject { build :conversation, :reply_sent }
      its('has_reply_been_sent?') { should be_true }
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
      subject.expires_at.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expires_at manually" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.update_expiry_time_based_on_seconds_to_live }.to change{subject.expires_at}.from(nil)
      subject.expires_at.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expires_at on save" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.save }.to change{subject.expires_at}.from(nil)
      subject.expires_at.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end
  end
  
  describe '#compare_answer' do
    let(:positive) { 'yes' }
    let(:negative) { 'no' }
    let(:failed) { 'walrus' }
    subject { build(:conversation, expected_confirmed_answer: positive, expected_denied_answer: negative) }

    it 'recognises positive answer' do
      subject.compare_answer( positive ).should == Conversation::CONFIRMED
    end

    it 'recognises uppercase positive answer' do
      subject.compare_answer( positive.upcase ).should == Conversation::CONFIRMED
    end

    it 'recognises padded positive answer' do
      subject.compare_answer( "   #{positive}   " ).should == Conversation::CONFIRMED
    end

    it 'recognises negative answer' do
      subject.compare_answer( negative ).should == Conversation::DENIED
    end
    
    it 'recognises uppercase negative answer' do
      subject.compare_answer( negative.upcase ).should == Conversation::DENIED
    end
    
    it 'recognises padded negative answer' do
      subject.compare_answer( "   #{negative}   " ).should == Conversation::DENIED
    end
    
    it 'ignores invalid answer' do
      subject.compare_answer( failed ).should == Conversation::FAILED
    end
    
    it 'ignores uppercase invalid answer' do
      subject.compare_answer( failed.upcase ).should == Conversation::FAILED
    end
    
    it 'ignores padded invalid answer' do
      subject.compare_answer( "   #{failed}   " ).should == Conversation::FAILED
    end

  end
  
  describe '#answer_applies?' do
    let(:positive) { 'yes' }
    let(:negative) { 'no' }
    let(:failed) { 'walrus' }
    subject { build(:conversation, expected_confirmed_answer: positive, expected_denied_answer: negative) }

    it 'recognises positive answer' do
      subject.answer_applies?( positive ).should be_true
    end

    it 'recognises uppercase positive answer' do
      subject.answer_applies?( positive.upcase ).should be_true
    end

    it 'recognises padded positive answer' do
      subject.answer_applies?( "   #{positive}   " ).should be_true
    end

    it 'recognises negative answer' do
      subject.answer_applies?( negative ).should be_true
    end
    
    it 'recognises uppercase negative answer' do
      subject.answer_applies?( negative.upcase ).should be_true
    end
    
    it 'recognises padded negative answer' do
      subject.answer_applies?( "   #{negative}   " ).should be_true
    end
    
    it 'ignores invalid answer' do
      subject.answer_applies?( failed ).should be_false
    end
    
    it 'ignores uppercase invalid answer' do
      subject.answer_applies?( failed.upcase ).should be_false
    end
    
    it 'ignores padded invalid answer' do
      subject.answer_applies?( "   #{failed}   " ).should be_false
    end
    
  end

end
