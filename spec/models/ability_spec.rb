require 'spec_helper'
require "cancan/matchers"

describe User, '.abilities' do

  let(:test_organization)  { create :organization, :test_twilio }
  let(:test_comm_gateway)  { test_organization.communication_gateways.first }
  let(:test_phone_number)  { create :phone_number, organization: test_organization, communication_gateway: test_comm_gateway }
  let(:test_phone_book)    { create :phone_book, organization: test_organization }
  let(:test_stencil)       { create :stencil, organization: test_organization, phone_book: test_phone_book }
  let(:test_conversation)  { create :conversation, stencil: test_stencil }
  let(:test_message)       { create :message, :challenge, conversation: test_conversation }
  let(:test_user)          { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: nil ) ] }
  let(:test_ledger_entry)  { create :ledger_entry, item: test_message }

  let(:other_organization) { create :organization, :test_twilio }
  let(:other_comm_gateway) { other_organization.communication_gateways.first }
  let(:other_phone_number) { create :phone_number, organization: other_organization, communication_gateway: other_comm_gateway }
  let(:other_phone_book)   { create :phone_book, organization: other_organization }
  let(:other_stencil)      { create :stencil, organization: other_organization, phone_book: other_phone_book }
  let(:other_conversation) { create :conversation, stencil: other_stencil }
  let(:other_message)      { create :message, :challenge, conversation: other_conversation }
  let(:other_user)         { create :user, user_roles: [ UserRole.new( organization: other_organization, roles: nil ) ] }
  let(:other_ledger_entry) { create :ledger_entry, item: other_message }
  
  context 'granting privileges' do
    it 'has no organizations' do
      user = create :user, user_roles: []
      user.user_roles.should be_empty
    end
    it 'has 1 organization' do
      user = create :user, user_roles: [
        UserRole.new( organization: test_organization, roles: [] )
      ]
      user.user_roles.should have(1).item
    end
    it 'has 2 organizations' do
      user = create :user, user_roles: [
        UserRole.new( organization: test_organization, roles: [] ),
        UserRole.new( organization: other_organization, roles: [] )
      ]
      user.user_roles.should have(2).items
    end
  end
  
  context 'as normal user' do
    subject { build :user, system_admin: false }
    it{ should_not have_ability(:manage, for: AccountPlan) }
  end
  
  context 'as system admin' do
    subject { build :user, system_admin: true }
    it{ should have_ability(:manage, for: AccountPlan) }
  end

  context "with default permissions" do
    subject { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: [] ) ] }

    # Test parent organization
    it{ should have_ability({index: true, new: true, create: true}, for: Organization) }
    it{ should have_ability({index: true, show: true, edit: false, update: false, destroy: false}, for: test_organization) }

    # Test non-parent organization - should have NO privileges
    it{ should have_ability({index: false, show: false, edit: false, update: false, destroy: false}, for: other_organization) }

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
  
  context 'as organization administrator' do
    subject { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: [ :organization_administrator ] ) ] }

    # Test users
    it{ should have_ability([:create, :read, :update, :destroy], for: test_user.user_roles.where( organization_id: test_organization.id ).first) }
    it{ should_not have_ability(:manage, for: test_user) }
    it{ should_not have_ability(:manage, for: other_user) }
  end

  context 'as developer' do
    subject { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: [ :developer ] ) ] }

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
    subject { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: [ :billing_liaison ] ) ] }

    # Test organization
    it{ should have_ability({index: true, show: true, edit: true, update: true, destroy: false}, for: test_organization) }
    it{ should_not have_ability(:manage, for: other_organization) }

    # Test viewing ledger entries
    it{ should have_ability({index: true, show: true, new: false, create: false, edit: false, update: false, destroy: false}, for: test_ledger_entry) }
    it{ should_not have_ability(:manage, for: other_ledger_entry) }
  end
  
  context 'as conversation manager' do
    subject { create :user, user_roles: [ UserRole.new( organization: test_organization, roles: [ :conversation_manager ] ) ] }

    # Test starting and forcing a conversation
    it{ should have_ability({index: true, show: true, new: true, create: true, edit: false, update: false, destroy: false, force: true}, for: test_conversation) }
    it{ should_not have_ability(:manage, for: other_conversation) }
  end

end
