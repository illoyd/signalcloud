require 'test_helper'

class StencilsControllerTest < ActionController::TestCase
  setup do
    @stencil = stencils(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:stencils)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create stencil" do
    assert_difference('Stencil.count') do
      post :create, stencil: { account: @stencil.account, encrypted_confirmed_reply: @stencil.encrypted_confirmed_reply, encrypted_denied_reply: @stencil.encrypted_denied_reply, encrypted_expected_confirmed_answer: @stencil.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @stencil.encrypted_expected_denied_answer, encrypted_expired_reply: @stencil.encrypted_expired_reply, encrypted_failed_reply: @stencil.encrypted_failed_reply, encrypted_question: @stencil.encrypted_question, phone_directory: @stencil.phone_directory, seconds_to_live: @stencil.seconds_to_live }
    end

    assert_redirected_to stencil_path(assigns(:stencil))
  end

  test "should show stencil" do
    get :show, id: @stencil
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @stencil
    assert_response :success
  end

  test "should update stencil" do
    put :update, id: @stencil, stencil: { account: @stencil.account, encrypted_confirmed_reply: @stencil.encrypted_confirmed_reply, encrypted_denied_reply: @stencil.encrypted_denied_reply, encrypted_expected_confirmed_answer: @stencil.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @stencil.encrypted_expected_denied_answer, encrypted_expired_reply: @stencil.encrypted_expired_reply, encrypted_failed_reply: @stencil.encrypted_failed_reply, encrypted_question: @stencil.encrypted_question, phone_directory: @stencil.phone_directory, seconds_to_live: @stencil.seconds_to_live }
    assert_redirected_to stencil_path(assigns(:stencil))
  end

  test "should destroy stencil" do
    assert_difference('Stencil.count', -1) do
      delete :destroy, id: @stencil
    end

    assert_redirected_to stencils_path
  end
end
