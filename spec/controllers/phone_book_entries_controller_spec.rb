require 'spec_helper'
describe PhoneBookEntriesController do
  let(:user)         { create :user }
  let(:plan)         { create :account_plan, :default }
  let(:organization) { create :organization, :test_twilio, account_plan: plan }
  let(:comm_gateway) { organization.communication_gateway_for :mock }
  let(:phone_book)   { create :phone_book, organization: organization }
  let(:phone_number) { create :phone_number, organization: organization, communication_gateway: comm_gateway }

  let(:phone_book_entry) { create :phone_book_entry, country: country, phone_book: phone_book, phone_number: phone_number }

  let(:country)      { 'US' }
  let(:create_payload)  {{ organization_id: organization.id, phone_book_entry: { country: country, phone_number_id: phone_number.id, phone_book_id: phone_book.id } }}

  # it_behaves_like 'an organization resource'

  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      user.is_developer_for?(organization).should be_false
    end

    describe 'POST create' do
      it 'redirects to root' do
        post :create, create_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not create phone_book' do
        expect{ post :create, create_payload }.not_to change( PhoneBookEntry, :count )
      end
    end

    describe 'DELETE destroy' do
      before { phone_book_entry }
      it 'redirects to root' do
        delete :destroy, organization_id: organization.id, id: phone_book_entry.id
        expect( response ).to redirect_to( '/' )
      end
      it 'does not destroy phone_book_entry' do
        expect{ delete :destroy, organization_id: organization.id, id: phone_book_entry.id }.not_to change( PhoneBookEntry, :count )
      end
    end

  end # as affiliated user

  context 'as developer' do
    before do
      user.set_roles_for( organization, [ :developer ] )
      sign_in user
    end

    it 'grants developer' do
      user.is_developer_for?(organization).should be_true
    end

    describe 'POST create' do
      it 'redirects to phone book page' do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, phone_book ] )
      end
      it 'creates a new entry' do
        expect{ post :create, create_payload }.to change( PhoneBookEntry, :count ).by(1)
      end
      it 'sets phone_book\'s country' do
        post :create, create_payload
        PhoneBookEntry.last.country.should == country
      end
      it 'sets phone_book\'s phone_number_id' do
        post :create, create_payload
        PhoneBookEntry.last.phone_number_id.should == phone_number.id
      end
      it 'redirect if no parameters' do
        post :create, organization_id: organization.id
        response.status.should == 302
      end
    end

    describe 'DELETE destroy' do
      before { phone_book_entry }
      it 'destroys phone_book' do
        expect{ delete :destroy, organization_id: organization.id, id: phone_book_entry.id }.to change( PhoneBookEntry, :count ).by(-1)
      end
    end

  end # as developer

end
