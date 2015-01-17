require "rails_helper"

RSpec.describe PhoneBooksController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/phone_books").to route_to("phone_books#index")
    end

    it "routes to #new" do
      expect(:get => "/phone_books/new").to route_to("phone_books#new")
    end

    it "routes to #show" do
      expect(:get => "/phone_books/1").to route_to("phone_books#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/phone_books/1/edit").to route_to("phone_books#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/phone_books").to route_to("phone_books#create")
    end

    it "routes to #update" do
      expect(:put => "/phone_books/1").to route_to("phone_books#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/phone_books/1").to route_to("phone_books#destroy", :id => "1")
    end

  end
end
