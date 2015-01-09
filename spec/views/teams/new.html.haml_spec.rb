require 'rails_helper'

RSpec.describe "teams/new", :type => :view do
  before(:each) do
    assign(:team, Team.new(
      :user => nil,
      :workflow_state => "MyString",
      :name => "MyString",
      :description => "MyText"
    ))
  end

  it "renders new team form" do
    render

    assert_select "form[action=?][method=?]", teams_path, "post" do

      assert_select "input#team_user_id[name=?]", "team[user_id]"

      assert_select "input#team_workflow_state[name=?]", "team[workflow_state]"

      assert_select "input#team_name[name=?]", "team[name]"

      assert_select "textarea#team_description[name=?]", "team[description]"
    end
  end
end
