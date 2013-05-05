require 'spec_helper'
require "cancan/matchers"

describe User, '.abilities' do

  let(:test_account) { create :account }
  let(:test_phone_number) { create :phone_number, account: test_account }
  let(:test_phone_book) { create :phone_book, account: test_account }
  let(:test_stencil) { create :stencil, account: test_account, phone_book: test_phone_book }
  let(:test_conversation) { create :conversation, stencil: test_stencil }
  let(:test_message) { create :message, conversation: test_conversation }
  let(:test_user) { create :user, account: test_account }
  let(:test_ledger_entry) { create :ledger_entry, item: test_message }

  let(:other_account) { create :account }
  let(:other_phone_number) { create :phone_number, account: other_account }
  let(:other_phone_book) { create :phone_book, account: other_account }
  let(:other_stencil) { create :stencil, account: other_account, phone_book: other_phone_book }
  let(:other_conversation) { create :conversation, stencil: other_stencil }
  let(:other_message) { create :message, conversation: other_conversation }
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
    
    # Test stencils
    it{ should have_ability({index: true, new: false, create: false}, for: Stencil) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_stencil) }
    it{ should_not have_ability(:manage, for: other_stencil) }
    
    # Test phone numbers
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_phone_number) }
    it{ should_not have_ability(:manage, for: other_phone_number) }
    
    # Test phone books
    it{ should have_ability({index: true, new: false, create: false}, for: PhoneNumber) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_phone_book) }
    it{ should_not have_ability(:manage, for: other_phone_book) }
    
    # Test conversations
    it{ should have_ability({index: true, new: false, create: false}, for: Conversation) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_conversation) }
    it{ should_not have_ability(:manage, for: other_conversation) }
    
    # Test messages
    it{ should have_ability({index: true, new: false, create: false}, for: Message) }
    it{ should have_ability({show: true, edit: false, update: false, destroy: false}, for: test_message) }
    it{ should_not have_ability(:manage, for: other_message) }
    
    # Test ledger_entries
    it{ should_not have_ability(:manage, for: LedgerEntry) }
    it{ should_not have_ability(:manage, for: test_ledger_entry) }
    it{ should_not have_ability(:manage, for: other_ledger_entry) }
  end
  
  context 'as super user' do
    subject { create(:super_user_user, account: test_account) }

    # Should be able to view and shadow other accounts
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: test_account) }
    it{ should have_ability({index: true, show: false, new: false, create: false, edit: false, update: false, destroy: false}, for: other_account) }
    it{ should have_ability( :shadow, for: test_account ) }
    it{ should have_ability( :shadow, for: other_account ) }
    
    # Should be able to manage AccountPlans
    it{ should have_ability( :manage, for: AccountPlan ) }
    it{ should have_ability( :manage, for: test_account.account_plan ) }
    it{ should have_ability( :manage, for: other_account.account_plan ) }
  end
  
  context 'as account administrator' do
    subject { create(:account_administrator_user, account: test_account) }

    # Test users
    it{ should have_ability(:manage, for: test_user) }
    it{ should_not have_ability(:manage, for: other_user) }
  end

  context 'as developer' do
    subject { create(:developer_user, account: test_account) }

    # Test stencils
    it{ should have_ability(:manage, for: test_stencil) }
    it{ should_not have_ability(:manage, for: other_stencil) }

    # Test phone book
    it{ should have_ability(:manage, for: test_phone_book) }
    it{ should_not have_ability(:manage, for: other_phone_book) }

    # Test phone numbers
    it{ should have_ability(:manage, for: test_phone_number) }
    it{ should_not have_ability(:manage, for: other_phone_number) }
  end
  
  context 'as billing liaison' do
    subject { create(:billing_liaison_user, account: test_account) }

    # Test account
    it{ should have_ability({index: false, show: true, new: false, create: false, edit: true, update: true, destroy: false}, for: test_account) }
    it{ should_not have_ability(:manage, for: other_account) }

    # Test viewing ledger entries
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: test_ledger_entry) }
    it{ should_not have_ability(:manage, for: other_ledger_entry) }
  end
  
  context 'as conversation manager' do
    subject { create(:conversation_manager_user, account: test_account) }

    # Test starting and forcing a conversation
    it{ should have_ability({index: true, show: true, new: true, create: true, edit: false, update: false, destroy: false, force: true}, for: test_conversation) }
    it{ should_not have_ability(:manage, for: other_conversation) }
  end

end
