require 'rails_helper'

RSpec.describe "phone_numbers/show", :type => :view do
  before(:each) do
    @phone_number = assign(:phone_number, PhoneNumber.create!(
      :type => "Type",
      :team => nil,
      :workflow_state => "Workflow State",
      :number => "Number",
      :provider_sid => "Provider Sid"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Type/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Workflow State/)
    expect(rendered).to match(/Number/)
    expect(rendered).to match(/Provider Sid/)
  end
end
