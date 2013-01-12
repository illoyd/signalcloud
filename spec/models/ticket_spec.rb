# encoding: UTF-8
require 'spec_helper'

describe Ticket do
  fixtures :account_plans, :accounts, :appliances, :tickets
  
  it { should belong_to :appliance }
  it { should have_many :messages }
  it { [ :seconds_to_live, :appliance_id, :actual_answer, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry ].each { |param| should allow_mass_assignment_of(param) } }
  it { [:appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry].each { |param| should validate_presence_of(param) } }
  
  describe "test phony" do
    
    Phony.normalize('+41 44 364 35 33').should == '41443643533'
    Phony.plausible?( '41 44 364 35 33' ).should == true
    Phony.plausible?( '+41 44 364 35 33' ).should == true
    Phony.plausible?( '+414436435 33' ).should == true
    
  end
  
  describe '.is_open?' do
    it 'should be open' do
      ticket = tickets( :test_ticket )
      # Open statuses
      [ Ticket::QUEUED, Ticket::CHALLENGE_SENT ].each do |status|
        ticket.status = status
        ticket.is_open?.should == true
      end
    end
    it 'should not be open' do
      ticket = tickets( :test_ticket )
      # Closed statuses
      [ Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].each do |status|
        ticket.status = status
        ticket.is_open?.should == false
      end
    end
  end
  
  describe '.is_closed?' do
    it 'should be closed' do
      ticket = tickets( :test_ticket )
      # Open statuses
      [ Ticket::QUEUED, Ticket::CHALLENGE_SENT ].each do |status|
        ticket.status = status
        ticket.is_closed?.should == false
      end
    end
    it 'should not be closed' do
      ticket = tickets( :test_ticket )
      # Closed statuses
      [ Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].each do |status|
        ticket.status = status
        ticket.is_closed?.should == true
      end
    end
  end
  
  describe '.has_errored?' do
    it 'should not be errored' do
      ticket = tickets( :test_ticket )
      # Open statuses
      [ Ticket::QUEUED, Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].each do |status|
        ticket.status = status
        ticket.has_errored?.should == false
      end
    end
    it 'should be errored' do
      ticket = tickets( :test_ticket )
      # Closed statuses
      [ Ticket::ERROR_INVALID_TO, Ticket::ERROR_INVALID_FROM, Ticket::ERROR_BLACKLISTED_TO, Ticket::ERROR_NOT_SMS_CAPABLE, Ticket::ERROR_CANNOT_ROUTE, Ticket::ERROR_SMS_QUEUE_FULL ].each do |status|
        ticket.status = status
        ticket.has_errored?.should == true
        ticket.is_closed?.should == true
      end
    end
  end
  
  describe '.normalize_message' do

    it 'should handle normal text' do
      Ticket.normalize_message( 'abcd1234' ).should == 'abcd1234'
      Ticket.normalize_message( 'ABCD1234' ).should == 'abcd1234'
      Ticket.normalize_message( 'AbCd1234' ).should == 'abcd1234'
      Ticket.normalize_message( 'aBcD 1234' ).should == 'abcd1234'
      Ticket.normalize_message( 'Hello!' ).should == 'hello'
      Ticket.normalize_message( 'Hello there, I love you!' ).should == 'hellothereiloveyou'
      Ticket.normalize_message( '      Hello there, I love you!   ' ).should == 'hellothereiloveyou'
    end

    it 'should handle diacritics text' do
      Ticket.normalize_message( "Café périferol" ).should == 'cafeperiferol'
      Ticket.normalize_message( "Cafe periferôl" ).should == 'cafeperiferol'
      Ticket.normalize_message( "Café périferôl" ).should == 'cafeperiferol'
    end

    it 'should handle japanese text' do
      Ticket.normalize_message( "こんにちは" ).should == "konnitiha"
      Ticket.normalize_message( "    こんにちは    " ).should == "konnitiha"
      Ticket.normalize_message( " こ ん           に ち は " ).should == "konnitiha"
      Ticket.normalize_message( " こ ん           に ち は 4  22 31 33" ).should == "konnitiha4223133"
    end

    it 'should handle special punctuation text' do
      
    end
    
    it 'should handle currencies' do
      Ticket.normalize_message( '$9.74' ).should == '974'
      Ticket.normalize_message( 'US$9.74' ).should == 'us974'
      Ticket.normalize_message( '¥1,000,564' ).should == '1000564'
      Ticket.normalize_message( '€5,321,987.45' ).should == '532198745'
      Ticket.normalize_message( '€5.321.987,45' ).should == '532198745'
      Ticket.normalize_message( 'S/.1,345.65' ).should == 's134565'
    end

  end

  describe ".has_challenge_been_sent?" do
    it "should be false when challenge_sent is blank" do
      ticket = tickets(:test_ticket)
      ticket.challenge_sent.should be_nil
      ticket.has_challenge_been_sent?.should == false
    end
    it "should be true when challenge_sent is set" do
      ticket = tickets(:test_ticket)
      ticket.challenge_sent = DateTime.now
      ticket.challenge_sent.should_not be_nil
      ticket.has_challenge_been_sent?.should == true
    end
  end

  describe ".has_response_been_received?" do
    it "should be false when response_received is blank" do
      ticket = tickets(:test_ticket)
      ticket.response_received.should be_nil
      ticket.has_challenge_been_sent?.should == false
    end
    it "should be true when response_received is set" do
      ticket = tickets(:test_ticket)
      ticket.response_received = DateTime.now
      ticket.response_received.should_not be_nil
      ticket.has_response_been_received?.should == true
    end
  end

  describe ".has_reply_been_sent?" do
    it "should be false when reply_sent is blank" do
      ticket = tickets(:test_ticket)
      ticket.reply_sent.should be_nil
      ticket.has_reply_been_sent?.should == false
    end
    it "should be true when reply_sent is set" do
      ticket = tickets(:test_ticket)
      ticket.reply_sent = DateTime.now
      ticket.reply_sent.should_not be_nil
      ticket.has_reply_been_sent?.should == true
    end
  end
  
  describe ".update_expiry_time_based_on_seconds_to_live" do
    it "should update expiry manually" do
      # Get ticket and original expiration timestamp
      ticket = tickets(:test_ticket)
      original_expiry = ticket.expiry
      ticket.seconds_to_live.should be_nil
      
      # Update the 'seconds_to_live' flag
      ticket.seconds_to_live = 360
      
      # And run the filter manually
      ticket.update_expiry_time_based_on_seconds_to_live
      ticket.expiry.should > original_expiry
      ticket.expiry.should be_within(0.5).of( 360.seconds.from_now )
    end

    it "should update expiry on create" do
      # Get ticket and original expiration timestamp
      ticket = tickets(:test_ticket).dup
      ticket.id.should be_nil
      ticket.expiry.should == tickets(:test_ticket).expiry
      ticket.seconds_to_live.should be_nil
      
      # Update the 'seconds_to_live' flag
      ticket.seconds_to_live = 360
      
      # And run the filter automatically durring save
      ticket.save
      ticket.expiry.should_not be_nil
      ticket.expiry.should be_within(0.5).of( 360.seconds.from_now )
    end

    it "should update expiry on update" do
      # Get ticket and original expiration timestamp
      ticket = tickets(:test_ticket)
      original_expiry = ticket.expiry
      ticket.seconds_to_live.should be_nil
      
      # Update the 'seconds_to_live' flag
      ticket.seconds_to_live = 360
      
      # And run the filter automatically during save
      ticket.save
      ticket.expiry.should > original_expiry
      ticket.expiry.should be_within(0.5).of( 360.seconds.from_now )
    end
  end
  
  describe ".send_challenge_message" do  
    before(:each) do
      @ticket = tickets(:test_ticket)
      @original_message_count = @ticket.messages.count
      @original_transaction_count = @ticket.appliance.account.transactions.count
    end

    context 'valid to and from numbers' do

      it "should send challenge" do
        expect{ @message = @ticket.send_challenge_message() }.to_not raise_error
        @message.body.should == @ticket.question
        @message.to_number.should == @ticket.to_number
        @message.from_number.should == @ticket.from_number
        
        # The message and transaction count should increase
        @ticket.messages.count.should == @original_message_count + 1
        @ticket.appliance.account.transactions.count.should == @original_transaction_count + 1
      end

      it "should not resend challenge" do
        # Trick ticket into thinking it has already sent a message
        @ticket.status = Ticket::CHALLENGE_SENT
        @ticket.challenge_sent = DateTime.now
        @ticket.challenge_status = Ticket::SENT
        
        # Attempt to send message
        expect{ @message = @ticket.send_challenge_message() }.to raise_error( Ticketplease::ChallengeAlreadySentError )
        
        # The message and transaction count should not increase
        @ticket.messages.count.should == @original_message_count
        @ticket.appliance.account.transactions.count.should == @original_transaction_count
      end

    end

    describe "should not send challenge" do
      after(:each) do
        # Message and transaction should not increase
        @ticket.messages.count.should == @original_message_count
        @ticket.appliance.account.transactions.count.should == @original_transaction_count
      end

      it "because invalid TO" do
        @ticket = tickets(:test_ticket_invalid_to)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count
        
        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_INVALID_TO
        end
        
        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_INVALID_TO
        @ticket.challenge_status.should == Ticket::ERROR_INVALID_TO
      end

      it "because routing is not possible" do
        @ticket = tickets(:test_ticket_cannot_route_to)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_CANNOT_ROUTE
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_CANNOT_ROUTE
        @ticket.challenge_status.should == Ticket::ERROR_CANNOT_ROUTE
      end

      it "because international support is disabled" do
        @ticket = tickets(:test_ticket_international_to)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::CriticalMessageSendingError )
          ex.code.should == Ticket::ERROR_INTERNATIONAL
        end
        
        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_INTERNATIONAL
        @ticket.challenge_status.should == Ticket::ERROR_INTERNATIONAL
      end

      it "because TO is on blacklist" do
        @ticket = tickets(:test_ticket_blacklisted_to)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_BLACKLISTED_TO
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_BLACKLISTED_TO
        @ticket.challenge_status.should == Ticket::ERROR_BLACKLISTED_TO
      end

      it "because TO is not SMS capable" do
        @ticket = tickets(:test_ticket_not_sms_capable_to)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_NOT_SMS_CAPABLE
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_NOT_SMS_CAPABLE
        @ticket.challenge_status.should == Ticket::ERROR_NOT_SMS_CAPABLE
      end

      it "because invalid FROM" do
        @ticket = tickets(:test_ticket_invalid_from)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_INVALID_FROM
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_INVALID_FROM
        @ticket.challenge_status.should == Ticket::ERROR_INVALID_FROM
      end

      it "because FROM is not SMS capable" do
        @ticket = tickets(:test_ticket_not_sms_capable_from)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_NOT_SMS_CAPABLE
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_NOT_SMS_CAPABLE
        @ticket.challenge_status.should == Ticket::ERROR_NOT_SMS_CAPABLE
      end

      it "because FROM has a full SMS queue" do
        @ticket = tickets(:test_ticket_sms_queue_full_from)
        @original_message_count = @ticket.messages.count
        @original_transaction_count = @ticket.appliance.account.transactions.count

        # Run command and expect an error
        expect{ @message = @ticket.send_challenge_message() }.to raise_error do |ex|
          ex.should be_a( Ticketplease::MessageSendingError )
          ex.code.should == Ticket::ERROR_SMS_QUEUE_FULL
        end

        # Verify that the ticket is now in an error status
        @ticket.has_errored?.should == true
        @ticket.status.should == Ticket::ERROR_SMS_QUEUE_FULL
        @ticket.challenge_status.should == Ticket::ERROR_SMS_QUEUE_FULL
      end

    end

  end

  describe ".send_reply_message" do
  
    context 'valid to and from numbers' do
      before(:each) do
        # Prepare a ticket by pretending it has already been sent
        @ticket = tickets(:test_ticket)
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

  end

end
