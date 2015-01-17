require 'rails_helper'

RSpec.describe "phone_books/show", :type => :view do
  before(:each) do
    @phone_book = assign(:phone_book, PhoneBook.create!(
      :team => nil,
      :workflow_state => "Workflow State",
      :name => "Name",
      :description => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Workflow State/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
