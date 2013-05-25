require 'spec_helper'

describe LedgerEntry do
  #fixtures :organizations, :stencils, :conversations, :messages, :ledger_entries
  
  describe "validations" do
    before(:all) { 3.times { create :ledger_entry } }
    [:organization_id, :narrative].each do |attribute|
      it { should validate_presence_of(attribute) }
    end

    [:organization_id, :item_id, :item_type, :narrative].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_numericality_of( :value ) }
    it { should belong_to :organization }
    it { should belong_to :item }
  end
  
  describe '#ensure_organization' do
    context 'item\'s organization is new' do
      let(:organization) { build :organization }
      let(:item) { build :phone_number, organization: organization }
      subject { build :ledger_entry, item: item, organization: nil }
      
      it 'updates organization' do
        expect{ subject.ensure_organization }.to change{subject.organization}.from(nil)
      end
      it 'does not update organization id' do
        expect{ subject.ensure_organization }.to_not change{subject.organization_id}.from(nil)
      end
    end
    
    context 'item\'s organization is persisted' do
      let(:organization) { create :organization }
      let(:item) { create :phone_number, organization: organization }
      subject { build :ledger_entry, item: item, organization: nil }

      it 'updates organization' do
        expect{ subject.ensure_organization }.to change{subject.organization}.from(nil)
      end
      it 'updates organization id' do
        expect{ subject.ensure_organization }.to change{subject.organization_id}.from(nil)
      end
    end
    
    context 'item\'s organization changes' do
      let(:organization) { create :organization }
      let(:other_organization) { create :organization }
      let(:item) { create :phone_number, organization: organization }
      subject { build :ledger_entry, item: item, organization: organization }

      it 'updates organization' do
        expect{ subject.item.organization = other_organization; subject.ensure_organization }.to change{subject.organization}.from(organization).to(other_organization)
      end
      it 'updates organization id' do
        expect{ subject.item.organization = other_organization; subject.ensure_organization }.to change{subject.organization_id}.from(organization.id).to(other_organization.id)
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
      organization = create :organization
      other_organization = create :organization
      rand_i(1,10).times { create :ledger_entry, :settled, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :pending, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, organization: organization, item: organization }

      rand_i(1,10).times { create :ledger_entry, :settled, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :pending, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, organization: other_organization, item: other_organization }
      
      @organization_id = organization.id
      @other_organization_id = other_organization.id
    end

    let(:organization) { Organization.find(@organization_id) }
    let(:other_organization) { Organization.find(@other_organization_id) }

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

    context 'when scoped to organization' do
      it "return pending entries for organization" do
        organization.ledger_entries.pending.each do |ledger_entry|
          ledger_entry.settled_at.should be_nil
          ledger_entry.is_pending?.should == true
          ledger_entry.is_settled?.should == false
        end
      end
    end
  end
  
  describe ".settled" do
    before(:all) do
      organization = create :organization
      other_organization = create :organization
      rand_i(1,10).times { create :ledger_entry, :settled, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :pending, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, organization: organization, item: organization }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, organization: organization, item: organization }

      rand_i(1,10).times { create :ledger_entry, :settled, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :pending, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :settled, :with_value, organization: other_organization, item: other_organization }
      rand_i(1,10).times { create :ledger_entry, :pending, :with_value, organization: other_organization, item: other_organization }

      @organization_id = organization.id
      @other_organization_id = other_organization.id
    end

    let(:organization) { Organization.find(@organization_id) }
    let(:other_organization) { Organization.find(@other_organization_id) }

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
    
    context 'when scoped to organization' do
      it "returns settled entries for organization" do
        organization.ledger_entries.settled.each do |ledger_entry|
          ledger_entry.organization.should eq(organization)
          ledger_entry.settled_at.should_not be_nil
          ledger_entry.is_pending?.should == false
          ledger_entry.is_settled?.should == true
        end
      end
    end
  end
  
  describe '#update_organization_balance' do
    let(:original_value) { BigDecimal.new "-0.8" }
    let(:new_value)      { BigDecimal.new "-1.2" }
    let(:organization)        { create :organization }
    let(:phone_number)   { create :phone_number, organization: organization }

    context 'when entry is new' do
      subject { build :ledger_entry, organization: organization, item: phone_number, value: original_value }

      it 'changes organization.balance' do
        expect{ subject.update_organization_balance }.to change(organization, :balance).by( original_value )
      end

    end

    context 'when value has changed' do
      subject { create :ledger_entry, organization: organization, item: phone_number, value: original_value }

      it 'changes organization.balance' do
        subject.value = new_value
        expect{ subject.update_organization_balance }.to change(organization, :balance).by( new_value - original_value )
      end

    end

    context 'when value has not changed' do
      subject { create :ledger_entry, organization: organization, item: phone_number, value: original_value }

      it 'does not change organization.balance' do
        subject.value = original_value
        expect{ subject.update_organization_balance }.not_to change(organization, :balance)
      end

    end

  end
  
#   describe ".new" do
#   
#     #before(:each) do
#       # Get all needed objects in the ownership chain
#       #@organization = organizations(:test_organization)
#       #@conversation = @organization.conversations.first
#       #@message = @conversation.messages.first
#     #end
# 
#     let(:organization) { create_freshbooks_account(10) }
#     #let(:conversation)  { organization.conversations.first }
#     let(:message) { organization.conversations.where( status: [Conversation::CHALLENGE_SENT, Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED] ).first.messages.first }
# 
#     it "should create a new pending ledger_entry from scratch" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = organization.ledger_entries.count
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = LedgerEntry.create( organization: organization, item: message, narrative: 'Trial assignment' )
#       ledger_entry.is_pending?.should == true
#       ledger_entry.is_settled?.should == false
#       ledger_entry.organization.should eq(organization)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_id.should == message.id
#       ledger_entry.item_type.should == message.class.name
#       ledger_entry.narrative.should == 'Trial assignment'
#       
#       # Count of ledger_entries should have increased by 1
#       organization.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#     it "should create a new pending ledger_entry from organization" do
#       message.should_not be_nil
#       
#       # Create a new ledger_entry from scratch
#       expect {
#         ledger_entry = organization.ledger_entries.create( item: message, narrative: 'Trial assignment' )
#         ledger_entry.is_pending?.should == true
#         ledger_entry.is_settled?.should == false
#         ledger_entry.organization.should eq(organization)
#         ledger_entry.item.should eq(message)
#         ledger_entry.item_id.should == message.id
#         ledger_entry.item_type.should == message.class.name        
#       }.to change{ organization.ledger_entries.count }.by(1)
#     end
# 
#     it "should create a new settled ledger_entry from scratch" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = organization.ledger_entries.count
#       
#       # Make an expected settled_at datetime
#       expected_settled_at = DateTime.now
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = LedgerEntry.create( organization: organization, item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
#       ledger_entry.settled_at.should == expected_settled_at
#       ledger_entry.is_pending?.should == false
#       ledger_entry.is_settled?.should == true
#       ledger_entry.organization.should eq(organization)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_type.should == message.class.name
#       ledger_entry.item_id.should == message.id
#       
#       # Count of ledger_entries should have increased by 1
#       organization.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#     it "should create a new settled ledger_entry from organization" do
#       # Count the number of ledger_entries for the message
#       original_ledger_entry_count = organization.ledger_entries.count
#       
#       # Make an expected settled_at datetime
#       expected_settled_at = DateTime.now
#       
#       # Create a new ledger_entry from scratch
#       ledger_entry = organization.ledger_entries.create( item: message, narrative: 'Trial assignment', settled_at: expected_settled_at )
#       ledger_entry.settled_at.should == expected_settled_at
#       ledger_entry.is_pending?.should == false
#       ledger_entry.is_settled?.should == true
#       ledger_entry.organization.should eq(organization)
#       ledger_entry.item.should eq(message)
#       ledger_entry.item_id.should == message.id
#       ledger_entry.item_type.should == message.class.name
#       
#       # Count of ledger_entries should have increased by 1
#       organization.ledger_entries.count.should == original_ledger_entry_count + 1
#     end
# 
#   end
  
end
