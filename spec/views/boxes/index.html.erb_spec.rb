require 'spec_helper'

describe "boxes/index", :type => :view do
  before(:each) do
    @organization = assign(:organization, stub_model(Organization))
    assign(:boxes, [
      stub_model(Box),
      stub_model(Box)
    ])
  end

  it "renders a list of boxes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
