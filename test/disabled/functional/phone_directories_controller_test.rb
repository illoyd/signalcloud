require 'test_helper'

class PhoneDirectoriesControllerTest < ActionController::TestCase
  setup do
    @phone_directory = phone_directories(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_directories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phone_directory" do
    assert_difference('PhoneDirectory.count') do
      post :create, phone_directory: { account: @phone_directory.account, description: @phone_directory.description, name: @phone_directory.name }
    end

    assert_redirected_to phone_directory_path(assigns(:phone_directory))
  end

  test "should show phone_directory" do
    get :show, id: @phone_directory
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @phone_directory
    assert_response :success
  end

  test "should update phone_directory" do
    put :update, id: @phone_directory, phone_directory: { account: @phone_directory.account, description: @phone_directory.description, name: @phone_directory.name }
    assert_redirected_to phone_directory_path(assigns(:phone_directory))
  end

  test "should destroy phone_directory" do
    assert_difference('PhoneDirectory.count', -1) do
      delete :destroy, id: @phone_directory
    end

    assert_redirected_to phone_directories_path
  end
end
