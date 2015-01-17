require 'rails_helper'

RSpec.describe "phone_books/index", :type => :view do
  before(:each) do
    assign(:phone_books, [
      PhoneBook.create!(
        :team => nil,
        :workflow_state => "Workflow State",
        :name => "Name",
        :description => "MyText"
      ),
      PhoneBook.create!(
        :team => nil,
        :workflow_state => "Workflow State",
        :name => "Name",
        :description => "MyText"
      )
    ])
  end

  it "renders a list of phone_books" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Workflow State".to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
