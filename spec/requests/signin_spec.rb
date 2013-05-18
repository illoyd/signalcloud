require 'spec_helper'

describe "Sign-in" do
  let(:user)         { create(:user, user_roles: [ UserRole.create(organization: organization, roles: []) ]) }
  let(:organization) { create(:organization) }

  context 'when not signed-in' do
    describe "GET /" do
      it 'raises forbidden' do
        get '/'
        response.status.should eq(302)
      end
    end
  end

  context 'when signed-in' do
    before(:each) { sign_in(user) }

    describe "GET /" do
      it 'passes auth' do
        get '/'
        response.status.should eq(200)
      end
    end

  end

end
