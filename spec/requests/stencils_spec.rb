require 'rails_helper'

RSpec.describe "Stencils", :type => :request do
  describe "GET /stencils" do
    it "works! (now write some real specs)" do
      get stencils_path
      expect(response).to have_http_status(200)
    end
  end
end
