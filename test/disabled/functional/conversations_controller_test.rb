require 'test_helper'

class ConversationsControllerTest < ActionController::TestCase
  setup do
    @conversation = conversations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conversations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conversation" do
    assert_difference('Conversation.count') do
      post :create, conversation: { stencil: @conversation.stencil, challenge_sent_at: @conversation.challenge_sent_at, encrypted_confirmed_reply: @conversation.encrypted_confirmed_reply, encrypted_denied_reply: @conversation.encrypted_denied_reply, encrypted_expected_confirmed_answer: @conversation.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @conversation.encrypted_expected_denied_answer, encrypted_expired_reply: @conversation.encrypted_expired_reply, encrypted_failed_reply: @conversation.encrypted_failed_reply, encrypted_from_number: @conversation.encrypted_from_number, encrypted_question: @conversation.encrypted_question, encrypted_to_number: @conversation.encrypted_to_number, expires_at: @conversation.expires_at, reply_sent_at: @conversation.reply_sent_at, response_received_at: @conversation.response_received_at, status: @conversation.status }
    end

    assert_redirected_to conversation_path(assigns(:conversation))
  end

  test "should show conversation" do
    get :show, id: @conversation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conversation
    assert_response :success
  end

  test "should update conversation" do
    put :update, id: @conversation, conversation: { stencil: @conversation.stencil, challenge_sent_at: @conversation.challenge_sent_at, encrypted_confirmed_reply: @conversation.encrypted_confirmed_reply, encrypted_denied_reply: @conversation.encrypted_denied_reply, encrypted_expected_confirmed_answer: @conversation.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @conversation.encrypted_expected_denied_answer, encrypted_expired_reply: @conversation.encrypted_expired_reply, encrypted_failed_reply: @conversation.encrypted_failed_reply, encrypted_from_number: @conversation.encrypted_from_number, encrypted_question: @conversation.encrypted_question, encrypted_to_number: @conversation.encrypted_to_number, expires_at: @conversation.expires_at, reply_sent_at: @conversation.reply_sent_at, response_received_at: @conversation.response_received_at, status: @conversation.status }
    assert_redirected_to conversation_path(assigns(:conversation))
  end

  test "should destroy conversation" do
    assert_difference('Conversation.count', -1) do
      delete :destroy, id: @conversation
    end

    assert_redirected_to conversations_path
  end
end
