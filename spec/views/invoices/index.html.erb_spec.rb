require 'rails_helper'

RSpec.describe "invoices/index", :type => :view do
  before(:each) do
    assign(:invoices, [
      Invoice.create!(),
      Invoice.create!()
    ])
  end

  it "renders a list of invoices" do
    render
  end
end
