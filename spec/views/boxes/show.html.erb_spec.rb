require 'spec_helper'

describe "boxes/show" do
  before(:each) do
    @organization = assign(:organization, stub_model(Organization))
    @box = assign(:box, stub_model(Box))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
