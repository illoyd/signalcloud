# encoding: UTF-8
require 'spec_helper'

describe Ticket do

  describe 'validations' do  
    it { should belong_to :appliance }
    it { should have_many :messages }

    [ :seconds_to_live, :appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at ].each do |attribute| 
      it { should allow_mass_assignment_of(attribute) }
    end

    [:appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expires_at].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end
  end
  
  describe '#is_open? and #is_closed? and #has_errored?' do
    [ Ticket::QUEUED, Ticket::CHALLENGE_SENT ].each do |status|
      context "when status is #{status}" do
        subject { build :ticket, status: status }
        its('is_open?') { should be_true }
        its('is_closed?') { should be_false }
        its('has_errored?') { should be_false }
      end
    end
    
    [ Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].each do |status|
      context "when status is #{status}" do
        subject { build :ticket, status: status }
        its('is_open?') { should be_false }
        its('is_closed?') { should be_true }
        its('has_errored?') { should be_false }
      end
    end
    
    [ Ticket::ERROR_INVALID_TO, Ticket::ERROR_INVALID_FROM, Ticket::ERROR_BLACKLISTED_TO, Ticket::ERROR_NOT_SMS_CAPABLE, Ticket::ERROR_CANNOT_ROUTE, Ticket::ERROR_SMS_QUEUE_FULL ].each do |status|
      context "when status is #{status}" do
        subject { build :ticket, status: status }
        its('is_open?') { should be_false }
        its('is_closed?') { should be_true }
        its('has_errored?') { should be_true }
      end
    end
  end
  
  describe "#has_challenge_been_sent?" do
    context 'when challenge not sent' do
      subject { build :ticket }
      its('has_challenge_been_sent?') { should be_false }
    end
    context 'when challenge sent' do
      subject { build :ticket, :challenge_sent }
      its('has_challenge_been_sent?') { should be_true }
    end
  end

  describe "#has_response_been_received?" do
    context 'when response has not been received' do
      subject { build :ticket }
      its('has_response_been_received?') { should be_false }
    end
    context 'when response has been received' do
      subject { build :ticket, :response_received }
      its('has_response_been_received?') { should be_true }
    end
  end

  describe "#has_reply_been_sent?" do
    context 'when reply not sent' do
      subject { build :ticket }
      its('has_reply_been_sent?') { should be_false }
    end
    context 'when reply sent' do
      subject { build :ticket, :reply_sent }
      its('has_reply_been_sent?') { should be_true }
    end
  end

  describe "#update_expiry_time_based_on_seconds_to_live" do
    let(:seconds_to_live) { 360 }
    let(:original_expiry) { 60.seconds.ago }
    subject { build :ticket, expires_at: nil }

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
  
  describe '#to_webhook_data' do

    context 'when pending' do
      subject { create(:ticket).to_webhook_data }
      it { should be_a Hash }
      it { should include( :id, :appliance_id, :status, :status_text, :created_at, :updated_at ) }
      its([:status]) { should == Ticket::PENDING }
      its([:open]) { should == 1 }
      its([:closed]) { should == 0 }
    end
    
    context 'when challenge is sent' do
      subject { create(:ticket, :challenge_sent).to_webhook_data }
      it { should be_a Hash }
      it { should include( :challenge_sent_at, :challenge_status ) }
      its([:status]) { should == Ticket::CHALLENGE_SENT }
      its([:open]) { should == 1 }
      its([:closed]) { should == 0 }
    end
    
    context 'when response is received' do
      subject { create(:ticket, :response_received).to_webhook_data }
      it { should be_a Hash }
      it { should include( :response_received_at ) }
    end

    context 'when reply is sent' do
      subject { create(:ticket, :reply_sent).to_webhook_data }
      it { should be_a Hash }
      it { should include( :reply_sent_at, :reply_status ) }
    end

    context 'when confirmed' do
      subject { create(:ticket, :confirmed, :reply_sent).to_webhook_data }
      its([:status]) { should == Ticket::CONFIRMED }
      its([:open]) { should == 0 }
      its([:closed]) { should == 1 }
    end

    context 'when denied' do
      subject { create(:ticket, :denied, :reply_sent).to_webhook_data }
      its([:status]) { should == Ticket::DENIED }
      its([:open]) { should == 0 }
      its([:closed]) { should == 1 }
    end

    context 'when failed' do
      subject { create(:ticket, :failed, :reply_sent).to_webhook_data }
      its([:status]) { should == Ticket::FAILED }
      its([:open]) { should == 0 }
      its([:closed]) { should == 1 }
    end

    context 'when expired' do
      subject { create(:ticket, :expired, :reply_sent).to_webhook_data }
      its([:status]) { should == Ticket::EXPIRED }
      its([:open]) { should == 0 }
      its([:closed]) { should == 1 }
    end

  end

end
