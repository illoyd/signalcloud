require 'test_helper'

class PhoneBookEntriesControllerTest < ActionController::TestCase
  setup do
    @phone_book_entry = phone_book_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_book_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phone_book_entry" do
    assert_difference('PhoneBookEntry.count') do
      post :create, phone_book_entry: { country: @phone_book_entry.country, book: @phone_book_entry.book, phone_number: @phone_book_entry.phone_number }
    end

    assert_redirected_to phone_book_entry_path(assigns(:phone_book_entry))
  end

  test "should show phone_book_entry" do
    get :show, id: @phone_book_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @phone_book_entry
    assert_response :success
  end

  test "should update phone_book_entry" do
    put :update, id: @phone_book_entry, phone_book_entry: { country: @phone_book_entry.country, book: @phone_book_entry.book, phone_number: @phone_book_entry.phone_number }
    assert_redirected_to phone_book_entry_path(assigns(:phone_book_entry))
  end

  test "should destroy phone_book_entry" do
    assert_difference('PhoneBookEntry.count', -1) do
      delete :destroy, id: @phone_book_entry
    end

    assert_redirected_to phone_book_entries_path
  end
end
