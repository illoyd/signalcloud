require 'spec_helper'

describe "Sign-in", :type => :request do
  let(:user)         { create(:user, user_roles: [ UserRole.create(organization: organization, roles: []) ]) }
  let(:organization) { create(:organization) }

  context 'when not signed-in' do
    describe "GET /" do
      it 'is moved permanently' do
        get '/'
        expect(response.status).to eq(301)
      end
      
      it 'redirects to sign-in' do
        get '/'
        expect(response).to redirect_to('/user/sign_in')
      end
    end
  end

  context 'when signed-in' do
    before(:each) { sign_in(user) }

    describe "GET /" do
      it 'passes auth' do
        get '/'
        expect(response.status).to eq(200)
      end
    end

  end

end
