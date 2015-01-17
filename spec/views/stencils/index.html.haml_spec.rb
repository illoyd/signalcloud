require 'rails_helper'

RSpec.describe "stencils/index", :type => :view do
  before(:each) do
    assign(:stencils, [
      Stencil.create!(
        :team => nil,
        :workflow_state => "Workflow State",
        :name => "Name",
        :description => "MyText",
        :phone_book => nil
      ),
      Stencil.create!(
        :team => nil,
        :workflow_state => "Workflow State",
        :name => "Name",
        :description => "MyText",
        :phone_book => nil
      )
    ])
  end

  it "renders a list of stencils" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Workflow State".to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
