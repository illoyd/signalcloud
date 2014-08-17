require "spec_helper"

describe BoxesController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/organizations/100/boxes")).to route_to("boxes#index", organization_id: '100' )
    end

    it "routes to #new" do
      expect(get("/organizations/100/boxes/new")).to route_to("boxes#new", organization_id: '100' )
    end

    it "routes to #show" do
      expect(get("/organizations/100/boxes/1")).to route_to("boxes#show", :id => "1", organization_id: '100' )
    end

    it "routes to #edit" do
      expect(get("/organizations/100/boxes/1/edit")).to route_to("boxes#edit", :id => "1", organization_id: '100' )
    end

    it "routes to #create" do
      expect(post("/organizations/100/boxes")).to route_to("boxes#create", organization_id: '100' )
    end

    it "routes to #update" do
      expect(put("/organizations/100/boxes/1")).to route_to("boxes#update", :id => "1", organization_id: '100' )
    end

    it "routes to #destroy" do
      expect(delete("/organizations/100/boxes/1")).to route_to("boxes#destroy", :id => "1", organization_id: '100' )
    end

  end
end
