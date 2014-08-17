shared_examples 'an organization resource' do
  let(:user)         { create :user }
  let(:plan)         { create :account_plan, :default }
  let(:organization) { create :organization, account_plan: plan }

  context 'as nobody' do

    describe 'GET index' do
      it 'redirects to home' do
        get :index, organization_id: organization.id
        expect( response ).to redirect_to( '/user/sign_in' )
      end
    end

  end

  context 'as unaffiliated user' do
    before do
      sign_in user
    end

    describe 'GET index' do
      before do
        sign_in user
        get :index, organization_id: organization.id
      end

      it 'redirects to root' do
        expect( response ).to redirect_to( '/' )
      end
    end
  end
  
  context 'as organization user' do
    before do
      user.set_roles_for( organization, UserRole::ROLES )
      sign_in user
    end

    describe 'GET index' do
      before do
        sign_in user
        get :index, organization_id: organization.id
      end

      it 'renders index' do
        expect( response ).to render_template( :index )
      end
      it 'assigns organization' do
        expect( assigns(:organization) ).to eq( organization )
      end
    end
  end
  
end