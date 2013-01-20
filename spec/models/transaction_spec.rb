require 'spec_helper'

describe Transaction do
  fixtures :accounts, :appliances, :tickets, :messages, :transactions
  
  describe "validations" do
    it { should belong_to :account }
    it { should belong_to :item }
    it { [:account_id, :item_id, :item_type, :narrative].each { |param| should validate_presence_of(param) } }
    it { [:account_id, :item_id, :item_type, :narrative].each { |param| should allow_mass_assignment_of(param) } }
    it { should validate_numericality_of( :value ) }
  end
  
  describe '.ensure_account' do
    it 'should refresh account when called' do
      tt = transactions(:outbound_sms_pending)
      tt.account_id.should == messages(:test_ticket_challenge).account.id
      tt.account_id = nil
      tt.account_id.should be_nil
      tt.ensure_account
      tt.account_id.should == messages(:test_ticket_challenge).account.id
    end
    it 'should reset account when item changes' do
      tt = transactions(:outbound_sms_pending)
      tt.account.should eq(accounts(:test_account))
      tt.item.should eq(messages(:test_ticket_challenge))
      tt.item = messages(:dedicated_ticket_challenge)
      tt.ensure_account
      tt.item.should eq(messages(:dedicated_ticket_challenge))
      tt.account.should eq(accounts(:dedicated_account))
    end
    it 'should reset account when saved' do
      tt = transactions(:outbound_sms_pending)
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
      tt = transactions(:outbound_sms_pending)
      tt.settled_at.should be_nil
      tt.is_pending?.should == true
      tt.is_settled?.should == false
    end
    it "should be false if settled_at is not blank" do
      tt = transactions(:outbound_sms_pending)
      tt.settled_at.should be_nil
      tt.is_pending?.should == true
      tt.is_settled?.should == false
    end
  end
  
  describe ".is_settled?" do
    it "should be true if settled_at is blank" do
      tt = transactions(:outbound_sms_settled)
      tt.settled_at.should_not be_nil
      tt.is_pending?.should == false
      tt.is_settled?.should == true
    end
    it "should be false if settled_at is not blank" do
      tt = transactions(:outbound_sms_settled)
      tt.settled_at.should_not be_nil
      tt.is_pending?.should == false
      tt.is_settled?.should == true
    end
  end
  
  describe ".pending" do
    it "should only return pending transactions" do
      pending = Transaction.pending
      pending.each do |transaction|
        transaction.settled_at.should be_nil
        transaction.is_pending?.should == true
        transaction.is_settled?.should == false
      end
    end
    it "should only not miss any pending transactions" do
      # Loop over all remaining transactions - they should NOT be pending
      (Transaction.all - Transaction.pending).each do |transaction|
        transaction.settled_at.should_not be_nil
        transaction.is_pending?.should == false
        transaction.is_settled?.should == true
      end
    end
  end
  
  describe ".settled" do
    it "should only return settled transactions" do
      settled = Transaction.settled
      settled.each do |transaction|
        transaction.settled_at.should_not be_nil
        transaction.is_pending?.should == false
        transaction.is_settled?.should == true
      end
    end
    it "should only not miss any settled transactions" do
      # Loop over all remaining transactions - they SHOULD be pending
      (Transaction.all - Transaction.settled).each do |transaction|
        transaction.settled_at.should be_nil
        transaction.is_pending?.should == true
        transaction.is_settled?.should == false
      end
    end
  end
  
  describe ".new" do
  
    before(:each) do
      # Get all needed objects in the ownership chain
      @account = accounts(:test_account)
      @ticket = @account.tickets.first
      @message = @ticket.messages.first
    end

    it "should create a new pending transaction from scratch" do
      # Count the number of transactions for the message
      original_transaction_count = @account.transactions.count
      
      # Create a new transaction from scratch
      transaction = Transaction.create( account: @account, item: @message, narrative: 'Trial assignment' )
      transaction.is_pending?.should == true
      transaction.is_settled?.should == false
      transaction.account.should eq(@account)
      transaction.item.should eq(@message)
      transaction.item_id.should == @message.id
      transaction.item_type.should == @message.class.name
      transaction.narrative.should == 'Trial assignment'
      
      # Count of transactions should have increased by 1
      @account.transactions.count.should == original_transaction_count + 1
    end

    it "should create a new pending transaction from account" do
      # Count the number of transactions for the message
      original_transaction_count = @account.transactions.count
      
      # Create a new transaction from scratch
      transaction = @account.transactions.create( item: @message, narrative: 'Trial assignment' )
      transaction.is_pending?.should == true
      transaction.is_settled?.should == false
      transaction.account.should eq(@account)
      transaction.item.should eq(@message)
      transaction.item_id.should == @message.id
      transaction.item_type.should == @message.class.name
      
      # Count of transactions should have increased by 1
      @account.transactions.count.should == original_transaction_count + 1
    end

    it "should create a new settled transaction from scratch" do
      # Count the number of transactions for the message
      original_transaction_count = @account.transactions.count
      
      # Make an expected settled_at datetime
      expected_settled_at = DateTime.now
      
      # Create a new transaction from scratch
      transaction = Transaction.create( account: @account, item: @message, narrative: 'Trial assignment', settled_at: expected_settled_at )
      transaction.settled_at.should == expected_settled_at
      transaction.is_pending?.should == false
      transaction.is_settled?.should == true
      transaction.account.should eq(@account)
      transaction.item.should eq(@message)
      transaction.item_id.should == @message.id
      transaction.item_type.should == @message.class.name
      
      # Count of transactions should have increased by 1
      @account.transactions.count.should == original_transaction_count + 1
    end

    it "should create a new settled transaction from account" do
      # Count the number of transactions for the message
      original_transaction_count = @account.transactions.count
      
      # Make an expected settled_at datetime
      expected_settled_at = DateTime.now
      
      # Create a new transaction from scratch
      transaction = @account.transactions.create( item: @message, narrative: 'Trial assignment', settled_at: expected_settled_at )
      transaction.settled_at.should == expected_settled_at
      transaction.is_pending?.should == false
      transaction.is_settled?.should == true
      transaction.account.should eq(@account)
      transaction.item.should eq(@message)
      transaction.item_id.should == @message.id
      transaction.item_type.should == @message.class.name
      
      # Count of transactions should have increased by 1
      @account.transactions.count.should == original_transaction_count + 1
    end

  end
  
end
