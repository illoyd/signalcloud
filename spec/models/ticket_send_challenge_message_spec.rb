# encoding: UTF-8
require 'spec_helper'

shared_examples 'sends messages' do |message_count, body_length|
  it 'does not raise error' do
    expect{ subject.send_challenge_message!() }.to_not raise_error
  end
  it "has #{message_count} messages" do
    subject.send_challenge_message!().should have(message_count).item
  end
  it 'assigns question to body' do
    subject.send_challenge_message!().first.body.should == subject.question[0,body_length]
  end
  it 'assigns customer_number to to_number' do
    subject.send_challenge_message!().first.to_number.should == subject.to_number
  end
  it 'assigns internal_number to from_number' do
    subject.send_challenge_message!().first.from_number.should == subject.from_number
  end
  it 'creates new message' do
    expect{ subject.send_challenge_message!() }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create new ledger entry' do
    # Does not create it because no price was given
    expect{ subject.send_challenge_message!() }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

shared_examples 'raises message error (without save)' do |message_count, error, error_code|
  it 'flags as error' do
    expect{ subject.send_challenge_message() }.to raise_error
    subject.has_errored?.should be_true
  end
  it "raises error" do
    expect{ subject.send_challenge_message() }.to raise_error( error )
  end
  it "raises error code" do
    expect{ subject.send_challenge_message() }.to raise_error { |ex| ex.code.should == error_code }
  end
  it 'does not create messages' do
    expect{ subject.send_challenge_message() rescue nil }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create ledger entries' do
    expect{ subject.send_challenge_message() rescue nil }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

shared_examples 'raises message error' do |message_count, error, error_code|
  it 'flags as error' do
    expect{ subject.send_challenge_message!() }.to raise_error
    subject.has_errored?.should be_true
  end
  it "raises error" do
    expect{ subject.send_challenge_message!() }.to raise_error( error )
  end
  it "raises error code" do
    expect{ subject.send_challenge_message!() }.to raise_error { |ex| ex.code.should == error_code }
  end
  it 'does not create messages' do
    expect{ subject.send_challenge_message!() rescue nil }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create ledger entries' do
    expect{ subject.send_challenge_message!() rescue nil }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

##
# Split out the +send_challenge_message+ function for ease of use
describe Ticket, '#send_challenge_message', :vcr => { :cassette_name => "ticket_send_challenge_message" } do

  let(:account) { create :account, :test_twilio, :with_sid_and_token }
  let(:phone_number) { create :phone_number, :valid_number, account: account }
  let(:phone_directory) { create :phone_directory, account: account }
  let(:stencil) { create :stencil, account: account, phone_directory: phone_directory }

  context 'when not already sent' do
    context 'and is typical' do
      subject { create :ticket, stencil: stencil }
      include_examples 'sends messages', 1, 160
    end
    
    context 'and has 160-character question' do
      subject { create :ticket, stencil: stencil, question: 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
      include_examples 'sends messages', 1, 160
    end
    
    context 'and has 1-character question' do
      subject { create :ticket, stencil: stencil, question: 'M' }
      include_examples 'sends messages', 1, 160
    end
    
    context 'and has 161-character question' do
      let(:question) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
      subject { create :ticket, stencil: stencil, question: question }
      include_examples 'sends messages', 2, 160
    end

    context 'and has super long question' do
      let(:question) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
      subject { create :ticket, stencil: stencil, question: question }
      include_examples 'sends messages', 5, 160
    end

    context 'and has UTF question' do
      subject { create :ticket, stencil: stencil, question: 'こんにちは' }
      include_examples 'sends messages', 1, 70
    end
    
    context 'and has 70-character UTF question' do
      subject { create :ticket, stencil: stencil, question: 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
      include_examples 'sends messages', 1, 70
    end
    
    context 'and has 71-character UTF question' do
      subject { create :ticket, stencil: stencil, question: 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
      include_examples 'sends messages', 2, 70
    end
    
    context 'and has super-long UTF question' do
      subject { create :ticket, stencil: stencil, question: 'こんにちは' * 30 }
      include_examples 'sends messages', 3, 70
    end
  end

  context 'when already sent' do
    subject { create :ticket, :challenge_sent, stencil: stencil }
    it "should not resend challenge" do
      expect{ subject.send_challenge_message!() }.to raise_error( SignalCloud::ChallengeAlreadySentError )
    end
  end
  
  context 'when missing body' do
    subject { build :ticket, stencil: stencil, question: nil }
    include_examples 'raises message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when blank body' do
    subject { build :ticket, stencil: stencil, question: '' }
    include_examples 'raises message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when spaced body' do
    subject { build :ticket, stencil: stencil, question: '    ' }
    include_examples 'raises message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when invalid TO' do
    subject { create :ticket, stencil: stencil, to_number: Twilio::INVALID_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INVALID_TO
  end
  
  context 'when TO has impossible routing' do
    subject { create :ticket, stencil: stencil, to_number: Twilio::INVALID_CANNOT_ROUTE_TO_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_CANNOT_ROUTE
  end
  
  context 'when international support is disabled' do
    subject { create :ticket, stencil: stencil, to_number: Twilio::INVALID_INTERNATIONAL_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INTERNATIONAL
  end
  
  context 'when TO is blacklisted' do
    subject { create :ticket, stencil: stencil, to_number: Twilio::INVALID_BLACKLISTED_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_BLACKLISTED_TO
  end
  
  context 'when TO is sms-incapable' do
    subject { create :ticket, stencil: stencil, to_number: Twilio::INVALID_NOT_SMS_CAPABLE_TO_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_NOT_SMS_CAPABLE
  end
  
  context 'when invalid FROM' do
    subject { create :ticket, stencil: stencil, from_number: Twilio::INVALID_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INVALID_FROM
  end
  
  context 'when sms-incapable FROM' do
    subject { create :ticket, stencil: stencil, from_number: Twilio::INVALID_NOT_SMS_CAPABLE_FROM_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_NOT_SMS_CAPABLE
  end
  
  context 'when FROM queue is full' do
    subject { create :ticket, stencil: stencil, from_number: Twilio::INVALID_FULL_SMS_QUEUE_NUMBER }
    include_examples 'raises message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_SMS_QUEUE_FULL
  end

end
