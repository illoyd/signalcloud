require 'spec_helper'

describe "Boxes" do
  let!(:user)          { create :user, user_roles: [ UserRole.create(organization: organization, roles: UserRole::ROLES) ] }
  let!(:organization)  { create :organization }
  let!(:box)           { create :box, organization: organization }
  before(:each) { sign_in(user) }

  describe "GET /boxes" do
    it "works!" do
      get organization_boxes_path(organization)
      response.status.should be(200)
    end
  end
end
