require 'rails_helper'

RSpec.describe "stencils/edit", :type => :view do
  before(:each) do
    @stencil = assign(:stencil, Stencil.create!(
      :team => nil,
      :workflow_state => "MyString",
      :name => "MyString",
      :description => "MyText",
      :phone_book => nil
    ))
  end

  it "renders the edit stencil form" do
    render

    assert_select "form[action=?][method=?]", stencil_path(@stencil), "post" do

      assert_select "input#stencil_team_id[name=?]", "stencil[team_id]"

      assert_select "input#stencil_workflow_state[name=?]", "stencil[workflow_state]"

      assert_select "input#stencil_name[name=?]", "stencil[name]"

      assert_select "textarea#stencil_description[name=?]", "stencil[description]"

      assert_select "input#stencil_phone_book_id[name=?]", "stencil[phone_book_id]"
    end
  end
end
