require 'rails_helper'

RSpec.describe "PhoneBooks", :type => :request do
  describe "GET /phone_books" do
    it "works! (now write some real specs)" do
      get phone_books_path
      expect(response).to have_http_status(200)
    end
  end
end
