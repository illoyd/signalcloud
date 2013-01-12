# encoding: UTF-8
require 'spec_helper'

##
# Split out the +send_challenge_message+ function for ease of use
describe Ticket do
  fixtures :account_plans, :accounts, :appliances, :tickets
  
  describe ".send_reply_message" do
  
    context 'with valid message' do
      before(:each) do
        # Prepare a ticket by pretending it has already been sent
        @ticket = tickets(:test_ticket)
        @ticket.status = Ticket::CHALLENGE_SENT
        @ticket.challenge_sent = DateTime.now
        @ticket.challenge_status = Ticket::SENT

        # Get counts for later use
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count
      end

      context 'reply not already sent' do
        after(:each) do
          # Check the message for content
          @message.should_not be_nil()
          @message.to_number.should == @ticket.to_number
          @message.from_number.should == @ticket.from_number
        
          # Message and transaction should not increase
          @ticket.messages.count.should == @original_message_count + 1
          @ticket.appliance.account.transactions.count.should == @original_transaction_count + 1
        end

        it "should send confirmed reply" do
          # Configure status to pick proper message
          @ticket.status = Ticket::CONFIRMED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to_not raise_error
          @message.body.should == @ticket.confirmed_reply
        end

        it "should send denied reply" do
          # Configure status to pick proper message
          @ticket.status = Ticket::DENIED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to_not raise_error
          @message.body.should == @ticket.denied_reply
        end

        it "should send failed reply" do
          # Configure status to pick proper message
          @ticket.status = Ticket::FAILED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to_not raise_error
          @message.body.should == @ticket.failed_reply
        end

        it "should send expired reply" do
          # Configure status to pick proper message
          @ticket.status = Ticket::EXPIRED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to_not raise_error
          @message.body.should == @ticket.expired_reply
        end
      end
    
      context 'reply already sent' do
        before(:each) do
          # Trick ticket into thinking it has already sent a reply
          @ticket.reply_sent = DateTime.now
          @ticket.reply_status = Ticket::SENT
        end
        after(:each) do
          # Message and transaction should not increase
          @ticket.messages.count.should == @original_message_count
          @ticket.appliance.account.transactions.count.should == @original_transaction_count
        end
        
        it "should not re-send confirmation reply" do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          @ticket.status = Ticket::CONFIRMED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to raise_error( Ticketplease::ReplyAlreadySentError )
        end
        
        it "should not re-send denied reply" do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          @ticket.status = Ticket::DENIED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to raise_error( Ticketplease::ReplyAlreadySentError )
        end
        
        it "should not re-send failed reply" do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          @ticket.status = Ticket::FAILED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to raise_error( Ticketplease::ReplyAlreadySentError )
        end
        
        it "should not re-send expired reply" do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          @ticket.status = Ticket::EXPIRED
  
          # Prepare and send message
          expect{ @message = @ticket.send_reply_message() }.to raise_error( Ticketplease::ReplyAlreadySentError )
        end
      end
    
    end

    context 'with invalid message' do
      before(:each) do
        subject.status = Ticket::CONFIRMED
        subject.challenge_sent = DateTime.now
        subject.challenge_status = Ticket::SENT
        @original_message_count = subject.messages.count
        @original_transaction_count = subject.appliance.account.transactions.count
      end
      after(:each) do
        # Ticket should have certain status - ticket is ok, but reply should be failed!
        subject.status.should == Ticket::CONFIRMED
        subject.reply_status.should == @expected_error
        subject.has_errored?.should == false

        # Message and transaction should not increase
        subject.messages.count.should == @original_message_count
        subject.appliance.account.transactions.count.should == @original_transaction_count
      end
      
      describe 'malformed body' do
        subject { tickets(:test_ticket) }
        it 'has a NIL confirmed reply' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.status = Ticket::CONFIRMED
          subject.confirmed_reply = nil
          @expected_error = Ticket::ERROR_MISSING_BODY

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
        it 'has a blank confirmed reply' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.status = Ticket::CONFIRMED
          subject.confirmed_reply = ''
          @expected_error = Ticket::ERROR_MISSING_BODY

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
        it 'has a 161-long confirmed reply' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.status = Ticket::CONFIRMED
          subject.confirmed_reply = 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin'
          @expected_error = Ticket::ERROR_BODY_TOO_LARGE

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
        it 'has a super long confirmed reply' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.status = Ticket::CONFIRMED
          subject.confirmed_reply = 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.'
          @expected_error = Ticket::ERROR_BODY_TOO_LARGE

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "invalid TO" do
        subject { tickets(:test_ticket_invalid_to) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_INVALID_TO

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "impossible routing" do
        subject { tickets(:test_ticket_cannot_route_to) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_CANNOT_ROUTE

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "international support is disabled" do
        subject { tickets(:test_ticket_international_to) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_INTERNATIONAL

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "blacklisted TO" do
        subject { tickets(:test_ticket_blacklisted_to) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_BLACKLISTED_TO

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "SMS-incapable TO" do
        subject { tickets(:test_ticket_not_sms_capable_to) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_NOT_SMS_CAPABLE

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "invalid FROM" do
        subject { tickets(:test_ticket_invalid_from) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_INVALID_FROM

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "SMS-incapable FROM" do
        subject { tickets(:test_ticket_not_sms_capable_from) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_NOT_SMS_CAPABLE

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
      describe "FROM SMS queue is full" do
        subject { tickets(:test_ticket_sms_queue_full_from) }
        it 'should not send message' do
          @expected_error = Ticket::ERROR_SMS_QUEUE_FULL

          # Run command and expect an error
          expect{ @message = subject.send_reply_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
    end

  end

end
