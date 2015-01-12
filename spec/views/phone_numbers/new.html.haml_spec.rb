require 'rails_helper'

RSpec.describe "phone_numbers/new", :type => :view do
  before(:each) do
    assign(:phone_number, PhoneNumber.new(
      :type => "",
      :team => nil,
      :workflow_state => "MyString",
      :number => "MyString",
      :provider_sid => "MyString"
    ))
  end

  it "renders new phone_number form" do
    render

    assert_select "form[action=?][method=?]", phone_numbers_path, "post" do

      assert_select "input#phone_number_type[name=?]", "phone_number[type]"

      assert_select "input#phone_number_team_id[name=?]", "phone_number[team_id]"

      assert_select "input#phone_number_workflow_state[name=?]", "phone_number[workflow_state]"

      assert_select "input#phone_number_number[name=?]", "phone_number[number]"

      assert_select "input#phone_number_provider_sid[name=?]", "phone_number[provider_sid]"
    end
  end
end
