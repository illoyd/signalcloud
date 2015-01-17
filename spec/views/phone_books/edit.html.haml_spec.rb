require 'rails_helper'

RSpec.describe "phone_books/edit", :type => :view do
  before(:each) do
    @phone_book = assign(:phone_book, PhoneBook.create!(
      :team => nil,
      :workflow_state => "MyString",
      :name => "MyString",
      :description => "MyText"
    ))
  end

  it "renders the edit phone_book form" do
    render

    assert_select "form[action=?][method=?]", phone_book_path(@phone_book), "post" do

      assert_select "input#phone_book_team_id[name=?]", "phone_book[team_id]"

      assert_select "input#phone_book_workflow_state[name=?]", "phone_book[workflow_state]"

      assert_select "input#phone_book_name[name=?]", "phone_book[name]"

      assert_select "textarea#phone_book_description[name=?]", "phone_book[description]"
    end
  end
end
