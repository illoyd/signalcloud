require "spec_helper"

describe BoxesController do
  describe "routing" do

    it "routes to #index" do
      get("/organizations/100/boxes").should route_to("boxes#index", organization_id: '100' )
    end

    it "routes to #new" do
      get("/organizations/100/boxes/new").should route_to("boxes#new", organization_id: '100' )
    end

    it "routes to #show" do
      get("/organizations/100/boxes/1").should route_to("boxes#show", :id => "1", organization_id: '100' )
    end

    it "routes to #edit" do
      get("/organizations/100/boxes/1/edit").should route_to("boxes#edit", :id => "1", organization_id: '100' )
    end

    it "routes to #create" do
      post("/organizations/100/boxes").should route_to("boxes#create", organization_id: '100' )
    end

    it "routes to #update" do
      put("/organizations/100/boxes/1").should route_to("boxes#update", :id => "1", organization_id: '100' )
    end

    it "routes to #destroy" do
      delete("/organizations/100/boxes/1").should route_to("boxes#destroy", :id => "1", organization_id: '100' )
    end

  end
end
