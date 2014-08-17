require 'spec_helper'
describe OrganizationsController, :type => :controller do

  it_behaves_like 'a protected resource'
  
  describe 'as affiliated user' do
    let(:user)         { create :user }
    let(:plan)         { create :account_plan, :default }
    let(:organization) { create :organization, account_plan: plan }
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      expect(user.is_billing_liaison_for?(organization)).to be_falsey
    end

    describe 'GET index' do
      it 'renders index' do
        get :index
        expect( response ).to render_template( :index )
      end
      it 'loads all organizations for signed-in user' do
        get :index
        expect(assigns(:organizations)).to match_array(user.reload.organizations)
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, id: organization.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, id: organization.id
        expect(assigns(:organization)).to eq(organization)
      end
    end

  end

  describe 'as billing liaison' do
    let(:user)         { create :user }
    let(:plan)         { create :account_plan, :default }
    let(:organization) { create :organization, account_plan: plan }
    before do
      user.set_roles_for( organization, [ :billing_liaison ] )
      sign_in user
    end
    
    it 'grants organization administrator' do
      expect(user.is_billing_liaison_for?(organization)).to be_truthy
    end

    describe 'GET new' do
      it 'renders new' do
        get :new
        expect( response ).to render_template( :new )
      end
      it 'assigns organization' do
        get :new
        expect(assigns(:organization)).to be_a_new Organization
      end
      
      it 'presents a complete organization' do
        get :new, complete: true
        expect(assigns(:organization)).to be_a_new Organization
      end
    end

    describe 'POST create' do
      it 'redirects to organization page' do
        post :create, organization: attributes_for(:organization)
        expect( response ).to redirect_to( Organization.last )
      end
      it 'creates a new organization' do
        expect{ post :create, organization: attributes_for(:organization) }.to change( Organization, :count ).by(1)
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :create }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'GET edit' do
      it 'renders edit' do
        get :edit, id: organization.id
        expect( response ).to render_template( :edit )
      end
      it 'assigns organization' do
        get :edit, id: organization.id
        expect(assigns(:organization)).to eq(organization)
      end

      it 'presents a complete organization' do
        get :edit, id: organization.id, complete: true
        expect(assigns(:organization)).to eq(organization)
      end
    end

    describe 'PUT update' do
      let(:new_label) { 'Test Title' }
      let(:new_description) { 'A new description' }
      let(:update_payload) {{ id: organization.id, organization: { label: new_label, description: new_description } }}
      it 'redirects to organization page' do
        put :update, update_payload
        expect( response ).to redirect_to( organization )
      end
      it 'does not create a new organization' do
        expect{ put :update, update_payload }.not_to change( Organization, :count )
      end
      it 'changes organization\'s label' do
        expect{ put :update, update_payload }.to change{ organization.reload.label }.to( new_label )
      end
      it 'changes organization\'s description' do
        expect{ put :update, update_payload }.to change{ organization.reload.description }.to( new_description )
      end
      it 'raises 400 bad request if no parameters' do
        expect{ put :update, id: organization.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

  end
end
