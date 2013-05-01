# encoding: UTF-8
require 'spec_helper'

shared_examples 'sends reply messages' do |body, message_count, body_length|
  it 'does not raise error' do
    expect{ subject.send_reply_message!() }.to_not raise_error
  end
  it "has #{message_count} messages" do
    subject.send_reply_message!().should have(message_count).item
  end
  it 'assigns question to body' do
    subject.send_reply_message!().first.body.should == subject.send(body)[0,body_length]
  end
  it 'assigns customer_number to to_number' do
    subject.send_reply_message!().first.to_number.should == subject.to_number
  end
  it 'assigns internal_number to from_number' do
    subject.send_reply_message!().first.from_number.should == subject.from_number
  end
  it 'creates new message' do
    expect{ subject.send_reply_message!() }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create new ledger entry' do
    # Does not create it because no price was given
    expect{ subject.send_reply_message!() }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

shared_examples 'raises reply message error (without save)' do |message_count, error, error_code|
  it 'flags as error' do
    expect{ subject.send_reply_message() }.to raise_error
    subject.has_errored?.should be_false # False here as failures in the REPLY are not documented in the message
  end
  it "raises error" do
    expect{ subject.send_reply_message() }.to raise_error( error )
  end
  it "raises error code" do
    expect{ subject.send_reply_message() }.to raise_error { |ex| ex.code.should == error_code }
  end
  it 'does not create messages' do
    expect{ subject.send_reply_message() rescue nil }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create ledger entries' do
    expect{ subject.send_reply_message() rescue nil }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

shared_examples 'raises reply message error' do |message_count, error, error_code|
  it 'flags as error' do
    expect{ subject.send_reply_message!() }.to raise_error
    subject.has_errored?.should be_false # False here as failures in the REPLY are not documented in the message
  end
  it "raises error" do
    expect{ subject.send_reply_message!() }.to raise_error( error )
  end
  it "raises error code" do
    expect{ subject.send_reply_message!() }.to raise_error { |ex| ex.code.should == error_code }
  end
  it 'does not create messages' do
    expect{ subject.send_reply_message!() rescue nil }.to change{subject.messages.count}.by(message_count)
  end
  it 'does not create ledger entries' do
    expect{ subject.send_reply_message!() rescue nil }.to_not change{subject.stencil.account.ledger_entries.count}
  end
end

##
# Split out the +send_reply_message+ function for ease of use
describe Ticket, '#send_reply_message', :vcr do

  let(:account) { create :account, :test_twilio, :with_sid_and_token }
  let(:phone_number) { create :phone_number, :valid_number, account: account }
  let(:phone_directory) { create :phone_directory, account: account }
  let(:stencil) { create :stencil, account: account, phone_directory: phone_directory }

  context 'when sending confirmation reply' do
    context 'when not already sent' do

      context 'and is typical' do
        let(:confirmed_reply) { 'confirmed' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 1, 160
      end
      
      context 'and has 160-character confirmed_reply' do
        let(:confirmed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 1, 160
      end
      
      context 'and has 1-character confirmed_reply' do
        let(:confirmed_reply) { 'M' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 1, 160
      end
      
      context 'and has 161-character confirmed_reply' do
        let(:confirmed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 2, 160
      end
  
      context 'and has super long confirmed_reply' do
        let(:confirmed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 5, 160
      end
  
      context 'and has UTF confirmed_reply' do
        let(:confirmed_reply) { 'こんにちは' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 1, 70
      end
      
      context 'and has 70-character UTF confirmed_reply' do
        let(:confirmed_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 1, 70
      end
      
      context 'and has 71-character UTF confirmed_reply' do
        let(:confirmed_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 2, 70
      end
      
      context 'and has super-long UTF confirmed_reply' do
        let(:confirmed_reply) { 'こんにちは' * 30 }
        subject { create :ticket, :challenge_sent, :response_received, :confirmed, stencil: stencil, confirmed_reply: confirmed_reply }
        include_examples 'sends reply messages', :confirmed_reply, 3, 70
      end
    end
  
    context 'when already sent' do
      subject { create :ticket, :challenge_sent, :response_received, :confirmed, :reply_sent, stencil: stencil }
      it "should not resend challenge" do
        expect{ subject.send_reply_message!() }.to raise_error( SignalCloud::ReplyAlreadySentError )
      end
    end
  end
    
  context 'when sending denied reply' do
    context 'when not already sent' do

      context 'and is typical' do
        let(:denied_reply) { 'denied' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 1, 160
      end
      
      context 'and has 160-character denied_reply' do
        let(:denied_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 1, 160
      end
      
      context 'and has 1-character denied_reply' do
        let(:denied_reply) { 'M' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 1, 160
      end
      
      context 'and has 161-character denied_reply' do
        let(:denied_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 2, 160
      end
  
      context 'and has super long denied_reply' do
        let(:denied_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 5, 160
      end
  
      context 'and has UTF denied_reply' do
        let(:denied_reply) { 'こんにちは' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 1, 70
      end
      
      context 'and has 70-character UTF denied_reply' do
        let(:denied_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 1, 70
      end
      
      context 'and has 71-character UTF denied_reply' do
        let(:denied_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 2, 70
      end
      
      context 'and has super-long UTF denied_reply' do
        let(:denied_reply) { 'こんにちは' * 30 }
        subject { create :ticket, :challenge_sent, :response_received, :denied, stencil: stencil, denied_reply: denied_reply }
        include_examples 'sends reply messages', :denied_reply, 3, 70
      end
    end
  
    context 'when already sent' do
      subject { create :ticket, :challenge_sent, :denied, :reply_sent, stencil: stencil }
      it "should not resend challenge" do
        expect{ subject.send_reply_message!() }.to raise_error( SignalCloud::ReplyAlreadySentError )
      end
    end
  end
    
  context 'when sending failed reply' do
    context 'when not already sent' do

      context 'and is typical' do
        let(:failed_reply) { 'failed' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 1, 160
      end
      
      context 'and has 160-character failed_reply' do
        let(:failed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 1, 160
      end
      
      context 'and has 1-character failed_reply' do
        let(:failed_reply) { 'M' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 1, 160
      end
      
      context 'and has 161-character failed_reply' do
        let(:failed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 2, 160
      end
  
      context 'and has super long failed_reply' do
        let(:failed_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 5, 160
      end
  
      context 'and has UTF failed_reply' do
        let(:failed_reply) { 'こんにちは' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 1, 70
      end
      
      context 'and has 70-character UTF failed_reply' do
        let(:failed_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 1, 70
      end
      
      context 'and has 71-character UTF failed_reply' do
        let(:failed_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 2, 70
      end
      
      context 'and has super-long UTF failed_reply' do
        let(:failed_reply) { 'こんにちは' * 30 }
        subject { create :ticket, :challenge_sent, :response_received, :failed, stencil: stencil, failed_reply: failed_reply }
        include_examples 'sends reply messages', :failed_reply, 3, 70
      end
    end
  
    context 'when already sent' do
      subject { create :ticket, :challenge_sent, :response_received, :failed, :reply_sent, stencil: stencil }
      it "should not resend challenge" do
        expect{ subject.send_reply_message!() }.to raise_error( SignalCloud::ReplyAlreadySentError )
      end
    end
  end
    
  context 'when sending expired reply' do
    context 'when not already sent' do

      context 'and is typical' do
        let(:expired_reply) { 'expired' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 1, 160
      end
      
      context 'and has 160-character expired_reply' do
        let(:expired_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 1, 160
      end
      
      context 'and has 1-character expired_reply' do
        let(:expired_reply) { 'M' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 1, 160
      end
      
      context 'and has 161-character expired_reply' do
        let(:expired_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 2, 160
      end
  
      context 'and has super long expired_reply' do
        let(:expired_reply) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 5, 160
      end
  
      context 'and has UTF expired_reply' do
        let(:expired_reply) { 'こんにちは' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 1, 70
      end
      
      context 'and has 70-character UTF expired_reply' do
        let(:expired_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 1, 70
      end
      
      context 'and has 71-character UTF expired_reply' do
        let(:expired_reply) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 2, 70
      end
      
      context 'and has super-long UTF expired_reply' do
        let(:expired_reply) { 'こんにちは' * 30 }
        subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: expired_reply }
        include_examples 'sends reply messages', :expired_reply, 3, 70
      end
    end
  
    context 'when already sent' do
      subject { create :ticket, :challenge_sent, :response_received, :expired, :reply_sent, stencil: stencil }
      it "should not resend challenge" do
        expect{ subject.send_reply_message!() }.to raise_error( SignalCloud::ReplyAlreadySentError )
      end
    end
  end
    
  context 'when missing body' do
    subject { build :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: nil }
    include_examples 'raises reply message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when blank body' do
    subject { build :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: '' }
    include_examples 'raises reply message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when spaced body' do
    subject { build :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, expired_reply: '    ' }
    include_examples 'raises reply message error (without save)', 0, SignalCloud::CriticalMessageSendingError, Ticket::ERROR_MISSING_BODY
  end
  
  context 'when invalid TO' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, to_number: Twilio::INVALID_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INVALID_TO
  end
  
  context 'when TO has impossible routing' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, to_number: Twilio::INVALID_CANNOT_ROUTE_TO_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_CANNOT_ROUTE
  end
  
  context 'when international support is disabled' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, to_number: Twilio::INVALID_INTERNATIONAL_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INTERNATIONAL
  end
  
  context 'when TO is blacklisted' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, to_number: Twilio::INVALID_BLACKLISTED_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_BLACKLISTED_TO
  end
  
  context 'when TO is sms-incapable' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, to_number: Twilio::INVALID_NOT_SMS_CAPABLE_TO_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_NOT_SMS_CAPABLE
  end
  
  context 'when invalid FROM' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, from_number: Twilio::INVALID_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_INVALID_FROM
  end
  
  context 'when sms-incapable FROM' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, from_number: Twilio::INVALID_NOT_SMS_CAPABLE_FROM_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_NOT_SMS_CAPABLE
  end
  
  context 'when FROM queue is full' do
    subject { create :ticket, :challenge_sent, :response_received, :expired, stencil: stencil, from_number: Twilio::INVALID_FULL_SMS_QUEUE_NUMBER }
    include_examples 'raises reply message error', 1, SignalCloud::MessageSendingError, Ticket::ERROR_SMS_QUEUE_FULL
  end

end
