require 'spec_helper'
describe ConversationsController do
  let(:user)            { create :user }
  let(:plan)            { create :account_plan, :default }
  let(:organization)    { create :organization, account_plan: plan }
  let(:stencil)         { create :stencil, organization: organization }
  let(:conversation)    { create :conversation, stencil: stencil }

  let(:to_number)       { Twilio::INVALID_NUMBER }
  let(:from_number)     { Twilio::VALID_NUMBER }
  let(:create_payload)  {{ organization_id: organization.id, stencil_id: stencil.id, conversation: { to_number: to_number, from_number: from_number } }}
  let(:update_payload)  {{ organization_id: organization.id, stencil_id: stencil.id, id: conversation.id, conversation: { to_number: to_number, from_number: from_number } }}

  it_behaves_like 'an organization resource'
  
  context 'as affiliated user' do
    before do
      user.set_roles_for( organization, UserRole::READ )
      sign_in user
    end

    it 'ensures user is unprivileged' do
      user.is_conversation_manager_for?(organization).should be_false
    end

    describe 'GET index' do
      before do
        create :conversation, stencil: stencil
        create :conversation, stencil: stencil
      end
        
      it 'renders index' do
        get :index, organization_id: organization.id
        expect( response ).to render_template( :index )
      end
      it 'loads all conversations for organization' do
        get :index, organization_id: organization.id
        assigns(:conversations).should =~ organization.conversations
      end
    end

    describe 'GET show' do
      it 'renders show' do
        get :show, organization_id: organization.id, id: conversation.id
        expect( response ).to render_template( :show )
      end
      it 'assigns organization' do
        get :show, organization_id: organization.id, id: conversation.id
        assigns(:conversation).should == conversation
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
      user.is_conversation_manager_for?(organization).should be_true
    end

    describe 'GET new' do
      it 'renders new' do
        get :new, organization_id: organization.id, stencil_id: stencil.id
        expect( response ).to render_template( :new )
      end
      it 'assigns conversation' do
        get :new, organization_id: organization.id, stencil_id: stencil.id
        assigns(:conversation).should be_a_new Conversation
      end
    end

    describe 'POST create' do
      it 'redirects to organization page', :focus do
        post :create, create_payload
        expect( response ).to redirect_to( [ organization, Conversation.last ] )
      end
      it 'creates a new organization' do
        expect{ post :create, create_payload }.to change( Conversation, :count ).by(1)
      end
      it 'sets conversation\'s to_number' do
        post :create, create_payload
        Conversation.last.to_number.should == to_number
      end
      it 'sets conversation\'s from_number' do
        post :create, create_payload
        Conversation.last.from_number.should == from_number
      end
      it 'raises 400 bad request if no parameters' do
        post :create, organization_id: organization.id, stencil_id: stencil.id
        response.status.should == 400
      end
    end

  end # as developer

end
