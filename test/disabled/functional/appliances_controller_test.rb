require 'test_helper'

class AppliancesControllerTest < ActionController::TestCase
  setup do
    @appliance = appliances(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:appliances)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create appliance" do
    assert_difference('Appliance.count') do
      post :create, appliance: { account: @appliance.account, encrypted_confirmed_reply: @appliance.encrypted_confirmed_reply, encrypted_denied_reply: @appliance.encrypted_denied_reply, encrypted_expected_confirmed_answer: @appliance.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @appliance.encrypted_expected_denied_answer, encrypted_expired_reply: @appliance.encrypted_expired_reply, encrypted_failed_reply: @appliance.encrypted_failed_reply, encrypted_question: @appliance.encrypted_question, phone_directory: @appliance.phone_directory, seconds_to_live: @appliance.seconds_to_live }
    end

    assert_redirected_to appliance_path(assigns(:appliance))
  end

  test "should show appliance" do
    get :show, id: @appliance
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @appliance
    assert_response :success
  end

  test "should update appliance" do
    put :update, id: @appliance, appliance: { account: @appliance.account, encrypted_confirmed_reply: @appliance.encrypted_confirmed_reply, encrypted_denied_reply: @appliance.encrypted_denied_reply, encrypted_expected_confirmed_answer: @appliance.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @appliance.encrypted_expected_denied_answer, encrypted_expired_reply: @appliance.encrypted_expired_reply, encrypted_failed_reply: @appliance.encrypted_failed_reply, encrypted_question: @appliance.encrypted_question, phone_directory: @appliance.phone_directory, seconds_to_live: @appliance.seconds_to_live }
    assert_redirected_to appliance_path(assigns(:appliance))
  end

  test "should destroy appliance" do
    assert_difference('Appliance.count', -1) do
      delete :destroy, id: @appliance
    end

    assert_redirected_to appliances_path
  end
end
