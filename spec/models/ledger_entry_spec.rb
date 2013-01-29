require 'spec_helper'

describe LedgerEntry do
  fixtures :accounts, :appliances, :tickets, :messages, :ledger_entries
  
  describe "validations" do
    it { should belong_to :account }
    it { should belong_to :item }
    it { [:account_id, :item_id, :item_type, :narrative].each { |param| should validate_presence_of(param) } }
    it { [:account_id, :item_id, :item_type, :narrative].each { |param| should allow_mass_assignment_of(param) } }
    it { should validate_numericality_of( :value ) }
  end
  
  describe '.ensure_account' do
    it 'should refresh account when called' do
      tt = ledger_entries(:outbound_sms_pending)
      tt.account_id.should == messages(:test_ticket_challenge).account.id
      tt.account_id = nil
      tt.account_id.should be_nil
      tt.ensure_account
      tt.account_id.should == messages(:test_ticket_challenge).account.id
    end
    it 'should reset account when item changes' do
      tt = ledger_entries(:outbound_sms_pending)
      tt.account.should eq(accounts(:test_account))
      tt.item.should eq(messages(:test_ticket_challenge))
      tt.item = messages(:dedicated_ticket_challenge)
      tt.ensure_account
      tt.item.should eq(messages(:dedicated_ticket_challenge))
      tt.account.should eq(accounts(:dedicated_account))
    end
    it 'should reset account when saved' do
      tt = ledger_entries(:outbound_sms_pending)
      tt.account.should eq(accounts(:test_account))
      tt.item.should eq(messages(:test_ticket_challenge))
      tt.item = messages(:dedicated_ticket_challenge)
      expect { tt.save! }.to_not raise_error
      tt.item.should eq(messages(:dedicated_ticket_challenge))
      tt.account.should eq(accounts(:dedicated_account))
    end
  end
  
  describe ".is_pending?" do
    it "should be true if settled_at is blank" do
      tt = ledger_entries(:outbound_sms_pending)
      tt.settled_at.should be_nil
      tt.is_pending?.should == true
      tt.is_settled?.should == false
    end
    it "should be false if settled_at is not blank" do
      tt = ledger_entries(:outbound_sms_pending)
      tt.settled_at.should be_nil
      tt.is_pending?.should == true
      tt.is_settled?.should == false
    end
  end
  
  describe ".is_settled?" do
    it "should be true if settled_at is blank" do
      tt = ledger_entries(:outbound_sms_settled)
      tt.settled_at.should_not be_nil
      tt.is_pending?.should == false
      tt.is_settled?.should == true
    end
    it "should be false if settled_at is not blank" do
      tt = ledger_entries(:outbound_sms_settled)
      tt.settled_at.should_not be_nil
      tt.is_pending?.should == false
      tt.is_settled?.should == true
    end
  end
  
  describe ".pending" do
    it "should only return pending ledger_entries" do
      pending = LedgerEntry.pending
      pending.each do |ledger_entry|
        ledger_entry.settled_at.should be_nil
        ledger_entry.is_pending?.should == true
        ledger_entry.is_settled?.should == false
      end
    end
    it "should only not miss any pending ledger_entries" do
      # Loop over all remaining ledger_entries - they should NOT be pending
      (LedgerEntry.all - LedgerEntry.pending).each do |ledger_entry|
        ledger_entry.settled_at.should_not be_nil
        ledger_entry.is_pending?.should == false
        ledger_entry.is_settled?.should == true
      end
    end
  end
  
  describe ".settled" do
    it "should only return settled ledger_entries" do
      settled = LedgerEntry.settled
      settled.each do |ledger_entry|
        ledger_entry.settled_at.should_not be_nil
        ledger_entry.is_pending?.should == false
        ledger_entry.is_settled?.should == true
      end
    end
    it "should only not miss any settled ledger_entries" do
      # Loop over all remaining ledger_entries - they SHOULD be pending
      (LedgerEntry.all - LedgerEntry.settled).each do |ledger_entry|
        ledger_entry.settled_at.should be_nil
        ledger_entry.is_pending?.should == true
        ledger_entry.is_settled?.should == false
      end
    end
  end
  
  describe ".new" do
  
    #before(:each) do
      # Get all needed objects in the ownership chain
      #@account = accounts(:test_account)
      #@ticket = @account.tickets.first
      #@message = @ticket.messages.first
    #end

    let(:account) { create_freshbooks_account(10) }
    #let(:ticket)  { account.tickets.first }
    let(:message) { account.tickets.where( status: [Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED] ).first.messages.first }

    it "should create a new pending ledger_entry from scratch" do
      # Count the number of ledger_entries for the message
      original_ledger_entry_count = account.ledger_entries.count
      
      # Create a new ledger_entry from scratch
      ledger_entry = LedgerEntry.create( account: account, item: message, narrative: 'Trial assignment' )
      ledger_entry.is_pending?.should == true
      ledger_entry.is_settled?.should == false
      ledger_entry.account.should eq(account)
      ledger_entry.item.should eq(message)
      ledger_entry.item_id.should == message.id
      ledger_entry.item_type.should == message.class.name
      ledger_entry.narrative.should == 'Trial assignment'
      
      # Count of ledger_entries should have increased by 1
      account.ledger_entries.count.should == original_ledger_entry_count + 1
    end

    it "should create a new pending ledger_entry from account" do
      message.should_not be_nil
      
      # Create a new ledger_entry from scratch
      expect {
        ledger_entry = account.ledger_entries.create( item: message, narrative: 'Trial assignment' )
        ledger_entry.is_pending?.should == true
        ledger_entry.is_settled?.should == false
        ledger_entry.account.should eq(account)
        ledger_entry.item.should eq(message)
        ledger_entry.item_id.should == message.id
        ledger_entry.item_type.should == message.class.name        
      }.to change{ account.ledger_entries.count }.by(1)
    end

    it "should create a new settled ledger_entry from scratch" do
      # Count the number of ledger_entries for the message
      original_ledger_entry_count = account.ledger_entries.count
      
      # Make an expected settled_at datetime
      expected_settled_at = DateTime.now
      
      # Create a new ledger_entry from scratch
      ledger_entry = LedgerEntry.create( account: account, item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
      ledger_entry.settled_at.should == expected_settled_at
      ledger_entry.is_pending?.should == false
      ledger_entry.is_settled?.should == true
      ledger_entry.account.should eq(account)
      ledger_entry.item.should eq(message)
      ledger_entry.item_type.should == message.class.name
      ledger_entry.item_id.should == message.id
      
      # Count of ledger_entries should have increased by 1
      account.ledger_entries.count.should == original_ledger_entry_count + 1
    end

    it "should create a new settled ledger_entry from account" do
      # Count the number of ledger_entries for the message
      original_ledger_entry_count = account.ledger_entries.count
      
      # Make an expected settled_at datetime
      expected_settled_at = DateTime.now
      
      # Create a new ledger_entry from scratch
      ledger_entry = account.ledger_entries.create( item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
      ledger_entry.settled_at.should == expected_settled_at
      ledger_entry.is_pending?.should == false
      ledger_entry.is_settled?.should == true
      ledger_entry.account.should eq(account)
      ledger_entry.item.should eq(message)
      ledger_entry.item_id.should == message.id
      ledger_entry.item_type.should == message.class.name
      
      # Count of ledger_entries should have increased by 1
      account.ledger_entries.count.should == original_ledger_entry_count + 1
    end

  end
  
end
