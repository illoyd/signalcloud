require 'spec_helper'
describe StencilsController, :type => :controller do
  let(:user)         { create :user }
  let(:plan)         { create :account_plan, :default }
  let(:organization) { create :organization, account_plan: plan }
  let(:stencil)      { create :stencil, organization: organization }

  let(:new_label)       { 'Test Title' }
  let(:new_description) { 'A new description' }
  let(:create_payload)  {{ organization_id: organization.id, stencil: { label: new_label, description: new_description } }}
  let(:update_payload)  {{ organization_id: organization.id, id: stencil.id, stencil: { label: new_label, description: new_description } }}

  it_behaves_like 'an organization resource'
  
  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      expect(user.is_developer_for?(organization)).to be_falsey
    end

    describe 'GET index' do
      before do
        create :stencil, organization: organization, active: true
        create :stencil, organization: organization, active: false
      end
        
      it 'renders index' do
        get :index, organization_id: organization.id
        expect( response ).to render_template( :index )
      end
      it 'loads all stencils for organization' do
        get :index, organization_id: organization.id
        expect(assigns(:stencils)).to match_array(organization.stencils)
      end
      it 'filters active stencils' do
        get :index, organization_id: organization.id, active_filter: true
        expect(assigns(:stencils)).to match_array(organization.reload.stencils.active)
      end
      it 'filters inactive stencils' do
        get :index, organization_id: organization.id, active_filter: false
        expect(assigns(:stencils)).to match_array(organization.reload.stencils.inactive)
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, organization_id: organization.id, id: stencil.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, organization_id: organization.id, id: stencil.id
        expect(assigns(:stencil)).to eq(stencil)
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
      it 'does not create stencil' do
        expect{ post :create, create_payload }.not_to change( Stencil, :count )
      end
    end

    describe 'GET edit' do
      it 'redirects to root' do
        get :edit, organization_id: organization.id, id: stencil.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'PUT update' do
      it 'redirects to root' do
        put :update, update_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not change stencil' do
        expect{ put :update, update_payload }.not_to change{ stencil.reload.label }
      end
    end

    describe 'DELETE destroy' do
      before { stencil }
      it 'redirects to root' do
        delete :destroy, organization_id: organization.id, id: stencil.id
        expect( response ).to redirect_to( '/' )
      end
      it 'does not destroy stencil' do
        expect{ delete :destroy, organization_id: organization.id, id: stencil.id }.not_to change( Stencil, :count )
      end
    end

  end # as affiliated user
  
  context 'as developer' do
    before do
      user.set_roles_for( organization, [ :developer ] )
      sign_in user
    end

    it 'grants developer' do
      expect(user.is_developer_for?(organization)).to be_truthy
    end

    describe 'GET new' do
      it 'renders new' do
        get :new, organization_id: organization.id
        expect( response ).to render_template( :new )
      end
      it 'assigns stencil' do
        get :new, organization_id: organization.id
        expect(assigns(:stencil)).to be_a_new Stencil
      end
    end

    describe 'POST create' do
      it 'redirects to organization page' do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, Stencil.last ] )
      end
      it 'creates a new organization' do
        expect{ post :create, create_payload }.to change( Stencil, :count ).by(1)
      end
      it 'sets stencil\'s label' do
        post :create, create_payload
        expect(Stencil.last.label).to eq(new_label)
      end
      it 'sets stencil\'s description' do
        post :create, create_payload
        expect(Stencil.last.description).to eq(new_description)
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :create, organization_id: organization.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'GET edit' do
      it 'renders edit' do
        get :edit, organization_id: organization.id, id: stencil.id
        expect( response ).to render_template( :edit )
      end
      it 'assigns stencil' do
        get :edit, organization_id: organization.id, id: stencil.id
        expect(assigns(:stencil)).to eq(stencil)
      end
    end

    describe 'PUT update' do
      it 'redirects to organization page' do
        put :update, update_payload
        expect( response ).to redirect_to( [ organization, stencil ] )
      end
      it 'does not create a new stencil' do
        stencil
        expect{ put :update, update_payload }.not_to change( Stencil, :count )
      end
      it 'changes stencil\'s label' do
        expect{ put :update, update_payload }.to change{ stencil.reload.label }.to( new_label )
      end
      it 'changes stencil\'s description' do
        expect{ put :update, update_payload }.to change{ stencil.reload.description }.to( new_description )
      end
      it 'raises 400 bad request if no parameters' do
        expect{ put :update, organization_id: organization.id, id: stencil.id }.to raise_error(ActionController::ParameterMissing)
      end
    end
    
    describe 'DELETE destroy' do
      before { stencil }
      it 'destroys stencil' do
        expect{ delete :destroy, organization_id: organization.id, id: stencil.id }.to change( Stencil, :count ).by(-1)
      end
    end

  end # as developer

end
