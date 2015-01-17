require 'rails_helper'

RSpec.describe "stencils/show", :type => :view do
  before(:each) do
    @stencil = assign(:stencil, Stencil.create!(
      :team => nil,
      :workflow_state => "Workflow State",
      :name => "Name",
      :description => "MyText",
      :phone_book => nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Workflow State/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
