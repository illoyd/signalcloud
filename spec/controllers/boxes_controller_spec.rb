require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe BoxesController, :type => :controller do
  let(:user)            { create :user }
  let(:organization)    { build :organization }
  let(:stencil)         { build :stencil, organization: organization }
  let(:box)             { create :box, organization: organization }
  let(:conversation)    { create :conversation, :with_internal_number, stencil: stencil, box: box }

  let(:box_label)       { 'Test Box' }
  let(:box_start_at)    { DateTime.now }
  let(:create_payload)  {{ organization_id: organization.id, box: { label: box_label, start_at: box_start_at } }}
  let(:update_payload)  { create_payload.merge({ id: box.id }) }

  it_behaves_like 'an organization resource'

  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
      box # Force the box to exist
    end

    it 'ensures user is unprivileged' do
      expect(user.is_conversation_manager_for?(organization)).to be_falsey
    end

    describe "GET index" do
      it 'renders index' do
        get :index, organization_id: organization.id
        expect( response ).to render_template( :index )
      end
      it "assigns all boxes as @boxes" do
        get :index, organization_id: organization.id
        expect(assigns(:boxes)).to match_array([box])
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, organization_id: organization.id, id: box.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, organization_id: organization.id, id: box.id
        expect(assigns(:organization)).to eq(organization)
      end
      it 'assigns box' do
        get :show, organization_id: organization.id, id: box.id
        expect(assigns(:box)).to eq(box)
      end
    end

    describe 'GET new' do
      it 'redirects to root' do
        get :new, organization_id: organization.id #, box_id: box.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'POST create' do
      it 'redirects to root' do
        post :create, create_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not create box' do
        expect{ post :create, create_payload }.not_to change( Box, :count )
      end
    end

    describe 'GET edit' do
      it 'redirects to root' do
        get :edit, organization_id: organization.id, id: box.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'POST update' do
      it 'redirects to root' do
        post :update, update_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not create box' do
        expect{ post :update, update_payload }.not_to change{ box.reload.label }
      end
    end

  end # affiliated user

  context 'as conversation manager'  do
    before do
      user.set_roles_for( organization, [ :conversation_manager ] )
      sign_in user
      box # Force the box to exist
    end

    it 'grants conversation manager' do
      expect(user.is_conversation_manager_for?(organization)).to be_truthy
    end

    describe 'GET new' do
      it 'renders new' do
        get :new, organization_id: organization.id
        expect( response ).to render_template( :new )
      end
      it 'assigns organization' do
        get :new, organization_id: organization.id
        expect(assigns(:organization)).to eq(organization)
      end
      it 'assigns a new box' do
        get :new, organization_id: organization.id
        expect(assigns(:box)).to be_a_new Box
      end
    end

    describe 'POST create' do
      it 'redirects to box\'s page' do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, Box.last ] )
      end
      it 'creates a new box' do
        expect{ post :create, create_payload }.to change( Box, :count ).by(1)
      end
      it 'sets box\'s label' do
        post :create, create_payload
        expect(Box.last.label).to eq(box_label)
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :create, organization_id: organization.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'GET edit' do
      it 'renders edit' do
        get :edit, organization_id: organization.id, id: box.id
        expect( response ).to render_template( :edit )
      end
      it 'assigns organization' do
        get :edit, organization_id: organization.id, id: box.id
        expect(assigns(:organization)).to eq(organization)
      end
      it 'assigns box' do
        get :edit, organization_id: organization.id, id: box.id
        expect(assigns(:box)).to eq(box)
      end
    end

    describe 'POST update' do
      it 'redirects to box\'s page' do
        post :update, update_payload
        expect( response ).to redirect_to( [ organization, box ] )
      end
      it 'does not create a new box' do
        expect{ post :update, update_payload }.not_to change( Box, :count )
      end
      it 'sets box\'s label' do
        expect{ post :update, update_payload }.to change{ box.reload.label }.to( box_label )
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :update, organization_id: organization.id, id: box.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested box" do
        expect { delete :destroy, organization_id: organization.id, id: box.id }.to change(Box, :count).by(-1)
      end
      it "destroys child conversations" do
        conversation
        expect { delete :destroy, organization_id: organization.id, id: box.id }.to change(Conversation, :count).by(-1)
      end
      it "redirects to the boxes list" do
        delete :destroy, organization_id: organization.id, id: box.id
        expect(response).to redirect_to( subject.organization_boxes_url( organization ) )
      end
    end

  end # conversation manager

end
