require 'rails_helper'

RSpec.describe "phone_books/new", :type => :view do
  before(:each) do
    assign(:phone_book, PhoneBook.new(
      :team => nil,
      :workflow_state => "MyString",
      :name => "MyString",
      :description => "MyText"
    ))
  end

  it "renders new phone_book form" do
    render

    assert_select "form[action=?][method=?]", phone_books_path, "post" do

      assert_select "input#phone_book_team_id[name=?]", "phone_book[team_id]"

      assert_select "input#phone_book_workflow_state[name=?]", "phone_book[workflow_state]"

      assert_select "input#phone_book_name[name=?]", "phone_book[name]"

      assert_select "textarea#phone_book_description[name=?]", "phone_book[description]"
    end
  end
end
