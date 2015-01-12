require 'rails_helper'

RSpec.describe "phone_numbers/index", :type => :view do
  before(:each) do
    assign(:phone_numbers, [
      PhoneNumber.create!(
        :type => "Type",
        :team => nil,
        :workflow_state => "Workflow State",
        :number => "Number",
        :provider_sid => "Provider Sid"
      ),
      PhoneNumber.create!(
        :type => "Type",
        :team => nil,
        :workflow_state => "Workflow State",
        :number => "Number",
        :provider_sid => "Provider Sid"
      )
    ])
  end

  it "renders a list of phone_numbers" do
    render
    assert_select "tr>td", :text => "Type".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Workflow State".to_s, :count => 2
    assert_select "tr>td", :text => "Number".to_s, :count => 2
    assert_select "tr>td", :text => "Provider Sid".to_s, :count => 2
  end
end
