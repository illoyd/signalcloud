require 'spec_helper'

describe "boxes/edit" do
  before(:each) do
    @organization = assign(:organization, stub_model(Organization))
    @box = assign(:box, stub_model(Box))
  end

  it "renders the edit box form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", organization_box_path(@organization, @box), "post" do
    end
  end
end
