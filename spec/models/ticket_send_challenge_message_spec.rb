# encoding: UTF-8
require 'spec_helper'

##
# Split out the +send_challenge_message+ function for ease of use
describe Ticket do
  fixtures :account_plans, :accounts, :appliances, :tickets
  before { VCR.insert_cassette 'ticket_send_challenge_message', record: :new_episodes }
  after { VCR.eject_cassette }

  describe ".send_challenge_message" do  

    context 'with not already sent' do
      subject { tickets(:test_ticket) }
      before(:each) do
        @original_message_count = subject.messages.count
        @original_transaction_count = subject.appliance.account.transactions.count
      end
      after(:each) do
        # The message and transaction count should increase
        subject.messages.count.should == @original_message_count + 1
        subject.appliance.account.transactions.count.should == @original_transaction_count + 1
      end

      it "should send typical challenge" do
        expect{ @message = subject.send_challenge_message() }.to_not raise_error
        @message.body.should == subject.question
        @message.to_number.should == subject.to_number
        @message.from_number.should == subject.from_number
      end

      it "should send challenge with 160-character question" do
        subject.question = 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi'
        expect{ @message = subject.send_challenge_message() }.to_not raise_error
        @message.body.should == subject.question
        @message.to_number.should == subject.to_number
        @message.from_number.should == subject.from_number
      end

      it "should send challenge with 1-character question" do
        subject.question = 'M'
        expect{ @message = subject.send_challenge_message() }.to_not raise_error
        @message.body.should == subject.question
        @message.to_number.should == subject.to_number
        @message.from_number.should == subject.from_number
      end

      it "should send challenge with UTF question" do
        subject.question = 'こんにちは'
        expect{ @message = subject.send_challenge_message() }.to_not raise_error
        @message.body.should == subject.question
        @message.to_number.should == subject.to_number
        @message.from_number.should == subject.from_number
      end
    end

    context 'with long bodies' do
      subject { tickets(:test_ticket) }
      before(:each) do
        @original_message_count = subject.messages.count
        @original_transaction_count = subject.appliance.account.transactions.count
      end

      it 'has a 161-long question' do
        # Configure status to pick proper message and trick it into thinking it has already been sent
        subject.question = 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin'

        # Run command and expect multiple messages to be returned
        expect{ @messages = subject.send_challenge_message() }.to_not raise_error
        @messages.should be_a(Array)
        @messages.size.should == 2

        # The message and transaction count should increase
        subject.messages.count.should == @original_message_count + 2
        subject.appliance.account.transactions.count.should == @original_transaction_count + 2
      end
      it 'has a super long question' do
        # Configure status to pick proper message and trick it into thinking it has already been sent
        subject.question = 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.'

        # Run command and expect multiple messages to be returned
        expect{ @messages = subject.send_challenge_message() }.to_not raise_error
        @messages.should be_a(Array)
        @messages.size.should == 5

        # The message and transaction count should increase
        subject.messages.count.should == @original_message_count + 5
        subject.appliance.account.transactions.count.should == @original_transaction_count + 5
      end
      it 'has a super long UTF-8 question' do
        # Configure status to pick proper message and trick it into thinking it has already been sent
        subject.question = 'こんにちは' * 20

        # Run command and expect multiple messages to be returned
        expect{ @messages = subject.send_challenge_message() }.to_not raise_error
        @messages.should be_a(Array)
        @messages.size.should == 2

        # The message and transaction count should increase
        subject.messages.count.should == @original_message_count + 2
        subject.appliance.account.transactions.count.should == @original_transaction_count + 2
      end
    end

    context 'when already sent' do
      subject { tickets(:test_ticket) }
      before(:each) do
        @original_message_count = subject.messages.count
        @original_transaction_count = subject.appliance.account.transactions.count
      end
      after(:each) do
        # The message and transaction count should increase
        subject.messages.count.should == @original_message_count
        subject.appliance.account.transactions.count.should == @original_transaction_count
      end

      it "should not resend challenge" do
        # Trick ticket into thinking it has already sent a message
        subject.status = Ticket::CHALLENGE_SENT
        subject.challenge_sent = DateTime.now
        subject.challenge_status = Message::SENT
        
        # Attempt to send message
        expect{ @message = subject.send_challenge_message() }.to raise_error( Ticketplease::ChallengeAlreadySentError )
      end
    end
    
    context 'with invalid message' do
      before(:each) do
        @original_message_count = subject.messages.count
        @original_transaction_count = subject.appliance.account.transactions.count
      end
      after(:each) do
        # Ticket should have certain errors and status
        subject.challenge_status.should == @expected_error
        subject.status.should == @expected_error
        subject.has_errored?.should == true

        # Message and transaction should not increase
        subject.messages.count.should == @original_message_count
        subject.appliance.account.transactions.count.should == @original_transaction_count
      end
      
      describe 'malformed body' do
        subject { tickets(:test_ticket) }
        it 'has a NIL question' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.question = nil
          @expected_error = Ticket::ERROR_MISSING_BODY

          # Run command and expect an error
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::CriticalMessageSendingError )
            ex.code.should == @expected_error
          }
        end
        it 'has a blank question' do
          # Configure status to pick proper message and trick it into thinking it has already been sent
          subject.question = ''
          @expected_error = Ticket::ERROR_MISSING_BODY

          # Run command and expect an error
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
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
          expect{ @message = subject.send_challenge_message() }.to raise_error { |ex|
            ex.should be_an_instance_of( Ticketplease::MessageSendingError )
            ex.code.should == @expected_error
          }
        end
      end
      
    end

  end

end
