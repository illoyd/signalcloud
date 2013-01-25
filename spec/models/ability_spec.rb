require 'spec_helper'
require "cancan/matchers"

describe User, '.abilities' do
  fixtures :accounts, :users, :phone_numbers, :phone_directories, :phone_directory_entries, :appliances, :tickets, :messages, :ledger_entries

  #subject { ability }
  #let(:ability){ Ability.new(user) }
  #let(:user){ nil }

#   context "when default without account" do
#     # We have to create this user as it is not valid for the database. This is just an extreme test case!
#     subject { User.new( email: 'bad@bad.com', first_name: 'Bad', last_name: 'User', roles: [] ) }
# 
#     it{ should_not be_able_to(:read, accounts(:test_account)) }
#   end

  context "when default with account" do
    subject { users(:default_permissions_user) }

    # Test parent account
    it{ should have_ability({index: false, new: false, create: false}, for: Account) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: accounts(:test_account)) }

    # Test non-parent account - should have NO privileges
    it{ should have_ability({show: false, edit: false, update: false, destroy: false}, for: accounts(:dedicated_account)) }

    # Test users
    it{ should have_ability({index: false, new: false, create: false}, for: User) }
    it{ should have_ability({show: true, edit: true, update: true, destroy: false}, for: users(:default_permissions_user)) }
    it{ should_not have_ability(:manage, for: users(:manage_account_permissions_user)) }
    it{ should_not have_ability(:manage, for: users(:dedicated_user)) }
    
    # Test appliances
    it{ should have_ability({index: true, new: false, create: false}, for: Appliance) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: appliances(:test_appliance)) }
    it{ should_not have_ability(:manage, for: appliances(:dedicated_appliance)) }
    
    # Test phone numbers
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: phone_numbers(:test_us)) }
    it{ should_not have_ability(:manage, for: phone_numbers(:dedicated_phone_number)) }
    
    # Test phone directories
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: phone_directories(:test_directory)) }
    it{ should_not have_ability(:manage, for: phone_directories(:dedicated_directory)) }
    
    # Test tickets
    it{ should have_ability({index: true, new: false, create: false}, for: Ticket) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: tickets(:test_ticket)) }
    it{ should_not have_ability(:manage, for: tickets(:dedicated_ticket)) }
    
    # Test messages
    it{ should have_ability({index: true, new: false, create: false}, for: Message) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: messages(:test_ticket_challenge)) }
    it{ should_not have_ability(:manage, for: messages(:dedicated_ticket_challenge)) }
    
    # Test ledger_entries
    it{ should_not have_ability(:manage, for: LedgerEntry) }
    it{ should_not have_ability(:manage, for: ledger_entries(:outbound_sms_1)) }
    it{ should_not have_ability(:manage, for: ledger_entries(:dedicated_outbound_sms_1)) }
  end
  
  context "can shadow account" do
    subject { users(:shadow_account_permissions_user) }

    # Test account
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: accounts(:test_account)) }
    it{ should have_ability({index: true, show: false, new: false, create: false, edit: false, update: false, destroy: false}, for: accounts(:dedicated_account)) }
    it{ should have_ability( :shadow, for: accounts(:test_account) ) }
    it{ should have_ability( :shadow, for: accounts(:dedicated_account) ) }
  end

  context "can manage account" do
    subject { users(:manage_account_permissions_user) }

    # Test account
    it{ should have_ability({index: false, show: true, new: false, create: false, edit: true, update: true, destroy: false}, for: accounts(:test_account)) }
    it{ should_not have_ability(:manage, for: accounts(:dedicated_account)) }
  end

  context "can manage users" do
    subject { users(:manage_users_permissions_user) }

    # Test users
    it{ should have_ability(:manage, for: users(:payg_user)) }
    it{ should_not have_ability(:manage, for: users(:dedicated_user)) }
  end

  context "can manage appliances" do
    subject { users(:manage_appliances_permissions_user) }

    # Test appliances
    it{ should have_ability(:manage, for: appliances(:test_appliance)) }
    it{ should_not have_ability(:manage, for: appliances(:dedicated_appliance)) }
  end

  context "can manage phone directories" do
    subject { users(:manage_phone_directories_permissions_user) }

    # Test appliances
    it{ should have_ability(:manage, for: phone_directories(:test_directory)) }
    it{ should_not have_ability(:manage, for: phone_directories(:dedicated_directory)) }
  end

  context "can manage phone numbers" do
    subject { users(:manage_phone_numbers_permissions_user) }

    # Test appliances
    it{ should have_ability(:manage, for: phone_numbers(:test_us)) }
    it{ should_not have_ability(:manage, for: phone_numbers(:dedicated_phone_number)) }
  end

  context "can start ticket" do
    subject { users(:start_ticket_permissions_user) }

    # Test appliances
    it{ should have_ability({index: true, show: true, new: true, create: true, edit: false, update: false, destroy: false, force: false}, for: tickets(:test_ticket)) }
    it{ should_not have_ability(:manage, for: tickets(:dedicated_ticket)) }
  end

  context "can force ticket" do
    subject { users(:force_ticket_permissions_user) }

    # Test appliances
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false, force: true}, for: tickets(:test_ticket)) }
    it{ should_not have_ability(:manage, for: tickets(:dedicated_ticket)) }
  end
  
  context 'can manage ledger_entries' do
    subject { users(:manage_ledger_entries_permissions_user) }
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: ledger_entries(:outbound_sms_1)) }
    it{ should_not have_ability(:manage, for: ledger_entries(:dedicated_outbound_sms_1)) }
  end
  
end
