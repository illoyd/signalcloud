require 'spec_helper'

describe Ticket do
  fixtures :account_plans, :accounts, :appliances, :tickets
  
  it { should belong_to :appliance }
  it { should have_many :messages }
  it { [ :seconds_to_live, :appliance_id, :actual_answer, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry ].each { |param| should allow_mass_assignment_of(param) } }
  it { [:appliance_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :from_number, :question, :to_number, :expiry].each { |param| should validate_presence_of(param) } }
  it { should ensure_length_of(:challenge_sms_sid).is_equal_to(TWILIO_SID_LENGTH) }
  it { should ensure_length_of(:reply_sms_sid).is_equal_to(TWILIO_SID_LENGTH) }
  it { should ensure_length_of(:response_sms_sid).is_equal_to(TWILIO_SID_LENGTH) }
  
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
      expect( ticket.expiry ).to be_within(0.5).of( 360.seconds.from_now )
    end

    it "should update expiry on create" do
      # Get ticket and original expiration timestamp
      ticket = tickets(:test_ticket).dup
      ticket.id.should be_nil
      ticket.expiry.should == tickets(:test_ticket).expiry
      ticket.seconds_to_live.should be_nil
      
      # Update the 'seconds_to_live' flag
      ticket.seconds_to_live = 360
      
      # And run the filter manually
      ticket.save
      expect( ticket.expiry ).to_not be_nil
    end

    it "should update expiry on update" do
      # Get ticket and original expiration timestamp
      ticket = tickets(:test_ticket)
      original_expiry = ticket.expiry
      ticket.seconds_to_live.should be_nil
      
      # Update the 'seconds_to_live' flag
      ticket.seconds_to_live = 360
      
      # And run the filter manually
      ticket.save
      expect( ticket.expiry ).to be_within(0.5).of(360.seconds.from_now)
    end
  end
  
  describe ".send_challenge" do

    it "should send challenge" do
      ticket = tickets(:test_ticket)
      original_message_count = ticket.messages.count
      expect{ @results = ticket.send_challenge() }.to_not raise_error
      @results.body.should == ticket.question
      @results.to.should == ticket.to_number
      @results.from.should == ticket.from_number
      
      # Was a new message saved?
      ticket.messages.count.should == ( original_message_count + 1 )
      
      # Get the last message, based upon the SID of the response
      message = ticket.messages.find_by_twilio_sid( @results.sid )
      message.should_not be_nil
      message.body.should == ticket.question
      message.to_number.should == ticket.to_number
      message.from_number.should == ticket.from_number
    end

    describe "should not send challenge" do

      it "because invalid TO" do
        ticket = tickets(:test_ticket_invalid_to)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_INVALID_TO
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because routing is not possible" do
        ticket = tickets(:test_ticket_cannot_route_to)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_CANNOT_ROUTE
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because international support is disabled" do
        ticket = tickets(:test_ticket_international_to)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to raise_error(Twilio::REST::RequestError)
        # ticket.status.should == Ticket::ERROR_INVALID_TO
        
        # Was a new message saved?
        # ticket.messages.count.should == original_message_count
      end

      it "because TO is on blacklist" do
        ticket = tickets(:test_ticket_blacklisted_to)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_BLACKLISTED_TO
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because TO is not SMS capable" do
        ticket = tickets(:test_ticket_not_sms_capable_to)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_NOT_SMS_CAPABLE
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because invalid FROM" do
        ticket = tickets(:test_ticket_invalid_from)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_INVALID_FROM
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because FROM is not SMS capable" do
        ticket = tickets(:test_ticket_not_sms_capable_from)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_NOT_SMS_CAPABLE
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

      it "because FROM has a full SMS queue" do
        ticket = tickets(:test_ticket_sms_queue_full_from)
        original_message_count = ticket.messages.count
        expect{ results = ticket.send_challenge() }.to_not raise_error
        ticket.status.should == Ticket::ERROR_SMS_QUEUE_FULL
        
        # Was a new message saved?
        ticket.messages.count.should == original_message_count
      end

    end

  end

end
