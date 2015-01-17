require "rails_helper"

RSpec.describe StencilsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/stencils").to route_to("stencils#index")
    end

    it "routes to #new" do
      expect(:get => "/stencils/new").to route_to("stencils#new")
    end

    it "routes to #show" do
      expect(:get => "/stencils/1").to route_to("stencils#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/stencils/1/edit").to route_to("stencils#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/stencils").to route_to("stencils#create")
    end

    it "routes to #update" do
      expect(:put => "/stencils/1").to route_to("stencils#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/stencils/1").to route_to("stencils#destroy", :id => "1")
    end

  end
end
