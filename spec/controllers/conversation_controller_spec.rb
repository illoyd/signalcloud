require 'spec_helper'
describe ConversationsController, :type => :controller do
  let(:user)            { create :user }
  let(:organization)    { stencil.organization }
  let(:stencil)         { conversation.stencil }
  let(:conversation)    { create :conversation, :with_stencil, :with_internal_number }

  let(:customer_number) { Twilio::INVALID_NUMBER }
  let(:internal_number) { conversation.internal_number }

  let(:create_attributes) {{ customer_number: customer_number, internal_number_id: internal_number.id }}
  let(:create_payload)    {{ organization_id: organization.id, stencil_id: stencil.id, conversation: create_attributes }} 

  it_behaves_like 'an organization resource'
  
  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      expect(user.is_conversation_manager_for?(organization)).to be_falsey
    end

    describe 'GET index' do
      before do
        create_list :conversation, 3, stencil: stencil, internal_number: internal_number
      end
        
      it 'renders index' do
        get :index, organization_id: organization.id
        expect( response ).to render_template( :index )
      end
      it 'loads all conversations for organization' do
        get :index, organization_id: organization.id
        expect(assigns(:conversations)).to match_array(organization.conversations)
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, organization_id: organization.id, id: conversation.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, organization_id: organization.id, id: conversation.id
        expect(assigns(:conversation)).to eq(conversation)
      end
    end
    
    describe 'GET new' do
      it 'redirects to root' do
        get :new, organization_id: organization.id, stencil_id: stencil.id
        expect( response ).to redirect_to( '/' )
      end
    end

    describe 'POST create' do
      it 'redirects to root' do
        post :create, create_payload
        expect( response ).to redirect_to( '/' )
      end
      it 'does not create conversation' do
        expect{ post :create, create_payload }.not_to change( Conversation, :count )
      end
    end

  end # as affiliated user
  
  context 'as conversation manager' do
    before do
      user.set_roles_for( organization, [ :conversation_manager ] )
      sign_in user
    end

    it 'grants conversation manager' do
      expect(user.is_conversation_manager_for?(organization)).to be_truthy
    end

    describe 'GET new' do
      it 'renders new' do
        get :new, organization_id: organization.id, stencil_id: stencil.id
        expect( response ).to render_template( :new )
      end
      it 'assigns conversation' do
        get :new, organization_id: organization.id, stencil_id: stencil.id
        expect(assigns(:conversation)).to be_a_new Conversation
      end
    end

    describe 'POST create' do
      it 'redirects to conversation page' do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, Conversation.last ] )
      end
      it 'creates a new conversation' do
        expect{ post :create, create_payload }.to change( Conversation, :count ).by(1)
      end
      it 'sets conversation\'s stencil' do
        post :create, create_payload
        expect(Conversation.last.stencil).to eq(stencil)
      end
      it 'sets conversation\'s customer_number' do
        post :create, create_payload
        expect(Conversation.last.customer_number.to_s).to eq(customer_number)
      end
      it 'sets conversation\'s internal_number' do
        post :create, create_payload
        expect(Conversation.last.internal_number).to eq(internal_number)
      end
      it 'raises 400 bad request if no parameters' do
        expect{ post :create, organization_id: organization.id, stencil_id: stencil.id }.to raise_error(ActionController::ParameterMissing)
      end
    end

  end # as developer

end
