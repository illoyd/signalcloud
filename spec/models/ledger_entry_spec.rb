require 'spec_helper'

describe LedgerEntry do
  #fixtures :accounts, :appliances, :tickets, :messages, :ledger_entries
  
  describe "validations" do
    before(:all) { 3.times { create :ledger_entry } }
    [:account_id, :item_id, :item_type, :narrative].each do |attribute|
      it { should validate_presence_of(attribute) }
    end

    [:account_id, :item_id, :item_type, :narrative].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_numericality_of( :value ) }
    it { should belong_to :account }
    it { should belong_to :item }
  end
  
  describe '#ensure_account' do
    context 'item\'s account is new' do
      let(:account) { build :account }
      let(:item) { build :phone_number, account: account }
      subject { build :ledger_entry, item: item, account: nil }
      
      it 'updates account' do
        expect{ subject.ensure_account }.to change{subject.account}.from(nil)
      end
      it 'does not update account id' do
        expect{ subject.ensure_account }.to_not change{subject.account_id}.from(nil)
      end
    end
    
    context 'item\'s account is persisted' do
      let(:account) { create :account }
      let(:item) { create :phone_number, account: account }
      subject { build :ledger_entry, item: item, account: nil }

      it 'updates account' do
        expect{ subject.ensure_account }.to change{subject.account}.from(nil)
      end
      it 'updates account id' do
        expect{ subject.ensure_account }.to change{subject.account_id}.from(nil)
      end
    end
    
    context 'item\'s account changes' do
      let(:account) { create :account }
      let(:other_account) { create :account }
      let(:item) { create :phone_number, account: account }
      subject { build :ledger_entry, item: item, account: account }

      it 'updates account' do
        expect{ subject.item.account = other_account; subject.ensure_account }.to change{subject.account}.from(account).to(other_account)
      end
      it 'updates account id' do
        expect{ subject.item.account = other_account; subject.ensure_account }.to change{subject.account_id}.from(account.id).to(other_account.id)
      end
    end
  end
  
  describe "#is_pending? and #is_settled?" do
    context 'when pending' do
      subject { create :ledger_entry, :pending }
      its(:'is_pending?') { should be_true }
      its(:'is_settled?') { should be_false }
    end

    context 'when settled' do
      subject { create :ledger_entry, :settled }
      its(:'is_pending?') { should be_false }
      its(:'is_settled?') { should be_true }
    end
  end
  
  describe "#pending" do
    before(:all) do
      account = create :account
      other_account = create :account
      rand_i(1,10).times { create :ledger_entry, :settled, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :pending, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, account: account, item: account }

      rand_i(1,10).times { create :ledger_entry, :settled, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :pending, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, account: other_account, item: other_account }
      
      @account_id = account.id
      @other_account_id = other_account.id
    end

    let(:account) { Account.find(@account_id) }
    let(:other_account) { Account.find(@other_account_id) }

    context 'when global' do
      it "returns pending entries" do
        LedgerEntry.pending.each do |ledger_entry|
          ledger_entry.settled_at.should be_nil
          ledger_entry.is_pending?.should == true
          ledger_entry.is_settled?.should == false
        end
      end
      it "does not miss any pending entries" do
        # Loop over all remaining ledger_entries - they should NOT be pending
        (LedgerEntry.all - LedgerEntry.pending).each do |ledger_entry|
          ledger_entry.settled_at.should_not be_nil
          ledger_entry.is_pending?.should == false
          ledger_entry.is_settled?.should == true
        end
      end
    end

    context 'when scoped to account' do
      it "return pending entries for account" do
        account.ledger_entries.pending.each do |ledger_entry|
          ledger_entry.settled_at.should be_nil
          ledger_entry.is_pending?.should == true
          ledger_entry.is_settled?.should == false
        end
      end
    end
  end
  
  describe ".settled" do
    before(:all) do
      account = create :account
      other_account = create :account
      rand_i(1,10).times { create :ledger_entry, :settled, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :pending, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, account: account, item: account }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, account: account, item: account }

      rand_i(1,10).times { create :ledger_entry, :settled, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :pending, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, account: other_account, item: other_account }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, account: other_account, item: other_account }

      @account_id = account.id
      @other_account_id = other_account.id
    end

    let(:account) { Account.find(@account_id) }
    let(:other_account) { Account.find(@other_account_id) }

    context 'when global' do
      it "returns settled entries" do
        LedgerEntry.settled.each do |ledger_entry|
          ledger_entry.settled_at.should_not be_nil
          ledger_entry.is_pending?.should == false
          ledger_entry.is_settled?.should == true
        end
      end
      it "does not miss any settled entries" do
        # Loop over all remaining ledger_entries - they SHOULD be pending
        (LedgerEntry.all - LedgerEntry.settled).each do |ledger_entry|
          ledger_entry.settled_at.should be_nil
          ledger_entry.is_pending?.should == true
          ledger_entry.is_settled?.should == false
        end
      end
    end
    
    context 'when scoped to account' do
      it "returns settled entries for account" do
        account.ledger_entries.settled.each do |ledger_entry|
          ledger_entry.account.should eq(account)
          ledger_entry.settled_at.should_not be_nil
          ledger_entry.is_pending?.should == false
          ledger_entry.is_settled?.should == true
        end
      end
    end
  end
  
#   describe ".new" do
#   
#     #before(:each) do
#       # Get all needed objects in the ownership chain
#       #@account = accounts(:test_account)
#       #@ticket = @account.tickets.first
#       #@message = @ticket.messages.first
#     #end
# 
#     let(:account) { create_freshbooks_account(10) }
#     #let(:ticket)  { account.tickets.first }
#     let(:message) { account.tickets.where( status: [Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED] ).first.messages.first }
# 
#     it "should create a new pending ledger_entry from scratch" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = account.ledger_entries.count
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = LedgerEntry.create( account: account, item: message, narrative: 'Trial assignment' )
#       ledger_entry.is_pending?.should == true
#       ledger_entry.is_settled?.should == false
#       ledger_entry.account.should eq(account)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_id.should == message.id
#       ledger_entry.item_type.should == message.class.name
#       ledger_entry.narrative.should == 'Trial assignment'
#       
#       # Count of ledger_entries should have increased by 1
#       account.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#     it "should create a new pending ledger_entry from account" do
#       message.should_not be_nil
#       
#       # Create a new ledger_entry from scratch
#       expect {
#         ledger_entry = account.ledger_entries.create( item: message, narrative: 'Trial assignment' )
#         ledger_entry.is_pending?.should == true
#         ledger_entry.is_settled?.should == false
#         ledger_entry.account.should eq(account)
#         ledger_entry.item.should eq(message)
#         ledger_entry.item_id.should == message.id
#         ledger_entry.item_type.should == message.class.name        
#       }.to change{ account.ledger_entries.count }.by(1)
#     end
# 
#     it "should create a new settled ledger_entry from scratch" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = account.ledger_entries.count
#       
#       # Make an expected settled_at datetime
#       expected_settled_at = DateTime.now
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = LedgerEntry.create( account: account, item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
#       ledger_entry.settled_at.should == expected_settled_at
#       ledger_entry.is_pending?.should == false
#       ledger_entry.is_settled?.should == true
#       ledger_entry.account.should eq(account)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_type.should == message.class.name
#       ledger_entry.item_id.should == message.id
#       
#       # Count of ledger_entries should have increased by 1
#       account.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#     it "should create a new settled ledger_entry from account" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = account.ledger_entries.count
#       
#       # Make an expected settled_at datetime
#       expected_settled_at = DateTime.now
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = account.ledger_entries.create( item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
#       ledger_entry.settled_at.should == expected_settled_at
#       ledger_entry.is_pending?.should == false
#       ledger_entry.is_settled?.should == true
#       ledger_entry.account.should eq(account)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_id.should == message.id
#       ledger_entry.item_type.should == message.class.name
#       
#       # Count of ledger_entries should have increased by 1
#       account.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#   end
  
end
