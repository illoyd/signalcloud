require "spec_helper"

RSpec.describe InvoicesController, :type => :routing do
  describe "routing", :type => :routing do

    it "routes to #index" do
      expect(:get => "organizations/20/invoices").to route_to("invoices#index", organization_id: "20")
    end

    it "routes to #pending" do
      expect(:get => "organizations/20/invoices/pending").to route_to("invoices#pending", organization_id: "20")
    end

    it "routes to #new" do
      pending
      expect(:get => "organizations/20/invoices/new").not_to be_routable
    end

    it "routes to #show" do
      expect(:get => "organizations/20/invoices/1").to route_to("invoices#show", :id => "1", organization_id: "20")
    end

    it "routes to #edit" do
      expect(:get => "organizations/20/invoices/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(:post => "organizations/20/invoices").not_to be_routable
    end

    it "routes to #update" do
      expect(:put => "organizations/20/invoices/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(:delete => "organizations/20/invoices/1").not_to be_routable
    end

  end
end
