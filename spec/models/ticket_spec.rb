# encoding: UTF-8
require 'spec_helper'

describe Ticket do

  describe 'validations' do  
    it { should belong_to :appliance }
    it { should have_many :messages }

    [ :seconds_to_live, :appliance_id, :actual_answer, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry ].each do |attribute| 
      it { should allow_mass_assignment_of(attribute) }
    end

    [:appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry].each do |attribute| 
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
    subject { build :ticket }

    it "updates overrides existing expiry" do
      subject.expiry = original_expiry
      subject.seconds_to_live = seconds_to_live
      expect { subject.update_expiry_time_based_on_seconds_to_live }.to change{subject.expiry}.from(original_expiry)
      subject.expiry.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expiry manually" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.update_expiry_time_based_on_seconds_to_live }.to change{subject.expiry}.from(nil)
      subject.expiry.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end

    it "updates expiry on save" do
      subject.seconds_to_live = seconds_to_live
      expect { subject.save }.to change{subject.expiry}.from(nil)
      subject.expiry.should be_within(0.5).of( seconds_to_live.seconds.from_now )
    end
  end

end
