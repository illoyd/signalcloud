require 'spec_helper'
require "cancan/matchers"

describe User, '.abilities' do

  let(:test_account) { create :account }
  let(:test_phone_number) { create :phone_number, account: test_account }
  let(:test_phone_directory) { create :phone_directory, account: test_account }
  let(:test_appliance) { create :appliance, account: test_account, phone_directory: test_phone_directory }
  let(:test_ticket) { create :ticket, appliance: test_appliance }
  let(:test_message) { create :message, ticket: test_ticket }
  let(:test_user) { create :user, account: test_account }
  let(:test_ledger_entry) { create :ledger_entry, item: test_message }

  let(:other_account) { create :account }
  let(:other_phone_number) { create :phone_number, account: other_account }
  let(:other_phone_directory) { create :phone_directory, account: other_account }
  let(:other_appliance) { create :appliance, account: other_account, phone_directory: other_phone_directory }
  let(:other_ticket) { create :ticket, appliance: other_appliance }
  let(:other_message) { create :message, ticket: other_ticket }
  let(:other_user) { create :user, account: other_account }
  let(:other_ledger_entry) { create :ledger_entry, item: other_message }

  context "with default permissions" do
    subject { create :user, account: test_account }

    # Test parent account
    it{ should have_ability({index: false, new: false, create: false}, for: Account) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_account) }

    # Test non-parent account - should have NO privileges
    it{ should have_ability({show: false, edit: false, update: false, destroy: false}, for: other_account) }

    # Test users
    it{ should have_ability({index: false, new: false, create: false}, for: User) }
    it{ should have_ability({show: true, edit: true, update: true, destroy: false}, for: subject) }
    it{ should_not have_ability(:manage, for: test_user) }
    it{ should_not have_ability(:manage, for: other_user) }
    
    # Test appliances
    it{ should have_ability({index: true, new: false, create: false}, for: Appliance) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_appliance) }
    it{ should_not have_ability(:manage, for: other_appliance) }
    
    # Test phone numbers
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_phone_number) }
    it{ should_not have_ability(:manage, for: other_phone_number) }
    
    # Test phone directories
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_phone_directory) }
    it{ should_not have_ability(:manage, for: other_phone_directory) }
    
    # Test tickets
    it{ should have_ability({index: true, new: false, create: false}, for: Ticket) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_ticket) }
    it{ should_not have_ability(:manage, for: other_ticket) }
    
    # Test messages
    it{ should have_ability({index: true, new: false, create: false}, for: Message) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_message) }
    it{ should_not have_ability(:manage, for: other_message) }
    
    # Test ledger_entries
    it{ should_not have_ability(:manage, for: LedgerEntry) }
    it{ should_not have_ability(:manage, for: test_ledger_entry) }
    it{ should_not have_ability(:manage, for: other_ledger_entry) }
  end
  
  context "can shadow account" do
    subject { create(:shadow_account_permissions_user, account: test_account) }

    # Test account
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: test_account) }
    it{ should have_ability({index: true, show: false, new: false, create: false, edit: false, update: false, destroy: false}, for: other_account) }
    it{ should have_ability( :shadow, for: test_account ) }
    it{ should have_ability( :shadow, for: other_account ) }
  end

  context "can manage account" do
    subject { create(:manage_account_permissions_user, account: test_account) }

    # Test account
    it{ should have_ability({index: false, show: true, new: false, create: false, edit: true, update: true, destroy: false}, for: test_account) }
    it{ should_not have_ability(:manage, for: other_account) }
  end

  context "can manage users" do
    subject { create(:manage_users_permissions_user, account: test_account) }

    # Test users
    it{ should have_ability(:manage, for: test_user) }
    it{ should_not have_ability(:manage, for: other_user) }
  end

  context "can manage appliances" do
    subject { create(:manage_appliances_permissions_user, account: test_account) }

    # Test appliances
    it{ should have_ability(:manage, for: test_appliance) }
    it{ should_not have_ability(:manage, for: other_appliance) }
  end

  context "can manage phone directories" do
    subject { create(:manage_phone_directories_permissions_user, account: test_account) }

    # Test appliances
    it{ should have_ability(:manage, for: test_phone_directory) }
    it{ should_not have_ability(:manage, for: other_phone_directory) }
  end

  context "can manage phone numbers" do
    subject { create(:manage_phone_numbers_permissions_user, account: test_account) }

    # Test appliances
    it{ should have_ability(:manage, for: test_phone_number) }
    it{ should_not have_ability(:manage, for: other_phone_number) }
  end

  context "can start ticket" do
    subject { create(:start_ticket_permissions_user, account: test_account) }

    # Test appliances
    it{ should have_ability({index: true, show: true, new: true, create: true, edit: false, update: false, destroy: false, force: false}, for: test_ticket) }
    it{ should_not have_ability(:manage, for: other_ticket) }
  end

  context "can force ticket" do
    subject { create(:force_ticket_permissions_user, account: test_account) }

    # Test appliances
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false, force: true}, for: test_ticket) }
    it{ should_not have_ability(:manage, for: other_ticket) }
  end
  
  context 'can manage ledger_entries' do
    subject { create(:manage_ledger_entries_permissions_user, account: test_account) }
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: test_ledger_entry) }
    it{ should_not have_ability(:manage, for: other_ledger_entry) }
  end
  
end
