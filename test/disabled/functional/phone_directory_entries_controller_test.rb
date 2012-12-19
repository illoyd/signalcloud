require 'test_helper'

class PhoneDirectoryEntriesControllerTest < ActionController::TestCase
  setup do
    @phone_directory_entry = phone_directory_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_directory_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phone_directory_entry" do
    assert_difference('PhoneDirectoryEntry.count') do
      post :create, phone_directory_entry: { country: @phone_directory_entry.country, directory: @phone_directory_entry.directory, phone_number: @phone_directory_entry.phone_number }
    end

    assert_redirected_to phone_directory_entry_path(assigns(:phone_directory_entry))
  end

  test "should show phone_directory_entry" do
    get :show, id: @phone_directory_entry
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @phone_directory_entry
    assert_response :success
  end

  test "should update phone_directory_entry" do
    put :update, id: @phone_directory_entry, phone_directory_entry: { country: @phone_directory_entry.country, directory: @phone_directory_entry.directory, phone_number: @phone_directory_entry.phone_number }
    assert_redirected_to phone_directory_entry_path(assigns(:phone_directory_entry))
  end

  test "should destroy phone_directory_entry" do
    assert_difference('PhoneDirectoryEntry.count', -1) do
      delete :destroy, id: @phone_directory_entry
    end

    assert_redirected_to phone_directory_entries_path
  end
end
