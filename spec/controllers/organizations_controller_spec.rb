require 'spec_helper'
describe OrganizationsController do

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
      user.is_billing_liaison_for?(organization).should be_false
    end

    describe 'GET index' do
      it 'renders index' do
        get :index
        expect( response ).to render_template( :index )
      end
      it 'loads all organizations for signed-in user' do
        get :index
        assigns(:organizations).should =~ user.reload.organizations
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, id: organization.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, id: organization.id
        assigns(:organization).should == organization
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
      user.is_billing_liaison_for?(organization).should be_true
    end

    describe 'GET new' do
      it 'renders new' do
        get :new
        expect( response ).to render_template( :new )
      end
      it 'assigns organization' do
        get :new
        assigns(:organization).should be_a_new Organization
      end
      
      it 'presents a complete organization' do
        get :new, complete: true
        assigns(:organization).should be_a_new Organization
      end
      it 'sets billing address' do
        get :new, complete: true
        assigns(:organization).billing_address.should be_a_new Address
      end
      it 'sets contact address' do
        get :new, complete: true
        assigns(:organization).contact_address.should be_a_new Address
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
        post :create
        response.status.should == 400
      end
    end

    describe 'GET edit' do
      it 'renders edit' do
        get :edit, id: organization.id
        expect( response ).to render_template( :edit )
      end
      it 'assigns organization' do
        get :edit, id: organization.id
        assigns(:organization).should == organization
      end

      it 'presents a complete organization' do
        get :edit, id: organization.id, complete: true
        assigns(:organization).should == organization
      end

      context 'when addresses are undefined' do
        let(:organization) { create :organization, account_plan: plan, contact_address: nil, billing_address: nil }
        it 'provides new billing address' do
          get :edit, id: organization.id, complete: true
          assigns(:organization).billing_address.should be_a_new Address
        end
        it 'provides new contact address' do
          get :edit, id: organization.id, complete: true
          assigns(:organization).contact_address.should be_a_new Address
        end
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
        put :update, id: organization.id
        response.status.should == 400
      end
    end

  end
end
