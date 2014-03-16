require 'spec_helper'
describe PhoneBooksController do
  let(:user)         { create :user }
  let(:plan)         { create :account_plan, :default }
  let(:organization) { create :organization, account_plan: plan }
  let(:phone_book)   { create :phone_book, organization: organization }

  let(:new_label)       { 'Test Title' }
  let(:new_description) { 'A new description' }
  let(:create_payload)  {{ organization_id: organization.id, phone_book: { label: new_label, description: new_description } }}
  let(:update_payload)  {{ organization_id: organization.id, id: phone_book.id, phone_book: { label: new_label, description: new_description } }}

  it_behaves_like 'an organization resource'
  
  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      user.is_developer_for?(organization).should be_false
    end

    describe 'GET index' do
      before do
        phone_book
      end
        
      it 'renders index' do
        get :index, organization_id: organization.id
        expect( response ).to render_template( :index )
      end
      it 'assigns phone books' do
        get :index, organization_id: organization.id
        assigns(:phone_books).should =~ organization.reload.phone_books
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, organization_id: organization.id, id: phone_book.id
        expect( response ).to render_template( :show )
      end
      it 'assigns phone book' do
        get :show, organization_id: organization.id, id: phone_book.id
        assigns(:phone_book).should == phone_book
      end
    end
    
    describe 'GET new' do
      it 'redirects to root' do
        get :new, organization_id: organization.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'POST create' do
      it 'redirects to root' do
        post :create, create_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not create phone_book' do
        expect{ post :create, create_payload }.not_to change( PhoneBook, :count )
      end
    end

    describe 'GET edit' do
      it 'redirects to root' do
        get :edit, organization_id: organization.id, id: phone_book.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'PUT update' do
      it 'redirects to root' do
        put :update, update_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not change phone_book' do
        expect{ put :update, update_payload }.not_to change{ phone_book.reload.label }
      end
    end

    describe 'DELETE destroy' do
      before { phone_book }
      it 'redirects to root' do
        delete :destroy, organization_id: organization.id, id: phone_book.id
        expect( response ).to redirect_to( '/' )
      end
      it 'does not destroy phone_book' do
        expect{ delete :destroy, organization_id: organization.id, id: phone_book.id }.not_to change( PhoneBook, :count )
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

    describe 'GET new' do
      it 'renders new' do
        get :new, organization_id: organization.id
        expect( response ).to render_template( :new )
      end
      it 'assigns phone_book' do
        get :new, organization_id: organization.id
        assigns(:phone_book).should be_a_new PhoneBook
      end
    end

    describe 'POST create' do
      it 'redirects to organization page' do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, PhoneBook.last ] )
      end
      it 'creates a new organization' do
        expect{ post :create, create_payload }.to change( PhoneBook, :count ).by(1)
      end
      it 'sets phone_book\'s label' do
        post :create, create_payload
        PhoneBook.last.label.should == new_label
      end
      it 'sets phone_book\'s description' do
        post :create, create_payload
        PhoneBook.last.description.should == new_description
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :create, organization_id: organization.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'GET edit' do
      it 'renders edit' do
        get :edit, organization_id: organization.id, id: phone_book.id
        expect( response ).to render_template( :edit )
      end
      it 'assigns phone_book' do
        get :edit, organization_id: organization.id, id: phone_book.id
        assigns(:phone_book).should == phone_book
      end
    end

    describe 'PUT update' do
      it 'redirects to organization page' do
        put :update, update_payload
        expect( response ).to redirect_to( [ organization, phone_book ] )
      end
      it 'does not create a new phone_book' do
        phone_book
        expect{ put :update, update_payload }.not_to change( PhoneBook, :count )
      end
      it 'changes phone_book\'s label' do
        expect{ put :update, update_payload }.to change{ phone_book.reload.label }.to( new_label )
      end
      it 'changes phone_book\'s description' do
        expect{ put :update, update_payload }.to change{ phone_book.reload.description }.to( new_description )
      end
      it 'raises 400 bad request if no parameters' do
        expect{ put :update, organization_id: organization.id, id: phone_book.id }.to raise_error(ActionController::ParameterMissing)
      end
    end
    
    describe 'DELETE destroy' do
      before { phone_book }
      it 'destroys phone_book' do
        expect{ delete :destroy, organization_id: organization.id, id: phone_book.id }.to change( PhoneBook, :count ).by(-1)
      end
    end

  end # as developer

end
