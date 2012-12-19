require 'test_helper'

class TicketsControllerTest < ActionController::TestCase
  setup do
    @ticket = tickets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tickets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ticket" do
    assert_difference('Ticket.count') do
      post :create, ticket: { appliance: @ticket.appliance, challenge_sent: @ticket.challenge_sent, challenge_sms_sid: @ticket.challenge_sms_sid, encrypted_actual_answer: @ticket.encrypted_actual_answer, encrypted_confirmed_reply: @ticket.encrypted_confirmed_reply, encrypted_denied_reply: @ticket.encrypted_denied_reply, encrypted_expected_confirmed_answer: @ticket.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @ticket.encrypted_expected_denied_answer, encrypted_expired_reply: @ticket.encrypted_expired_reply, encrypted_failed_reply: @ticket.encrypted_failed_reply, encrypted_from_number: @ticket.encrypted_from_number, encrypted_question: @ticket.encrypted_question, encrypted_to_number: @ticket.encrypted_to_number, expiry: @ticket.expiry, reply_sent: @ticket.reply_sent, reply_sms_sid: @ticket.reply_sms_sid, response_received: @ticket.response_received, response_sms_sid: @ticket.response_sms_sid, status: @ticket.status }
    end

    assert_redirected_to ticket_path(assigns(:ticket))
  end

  test "should show ticket" do
    get :show, id: @ticket
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ticket
    assert_response :success
  end

  test "should update ticket" do
    put :update, id: @ticket, ticket: { appliance: @ticket.appliance, challenge_sent: @ticket.challenge_sent, challenge_sms_sid: @ticket.challenge_sms_sid, encrypted_actual_answer: @ticket.encrypted_actual_answer, encrypted_confirmed_reply: @ticket.encrypted_confirmed_reply, encrypted_denied_reply: @ticket.encrypted_denied_reply, encrypted_expected_confirmed_answer: @ticket.encrypted_expected_confirmed_answer, encrypted_expected_denied_answer: @ticket.encrypted_expected_denied_answer, encrypted_expired_reply: @ticket.encrypted_expired_reply, encrypted_failed_reply: @ticket.encrypted_failed_reply, encrypted_from_number: @ticket.encrypted_from_number, encrypted_question: @ticket.encrypted_question, encrypted_to_number: @ticket.encrypted_to_number, expiry: @ticket.expiry, reply_sent: @ticket.reply_sent, reply_sms_sid: @ticket.reply_sms_sid, response_received: @ticket.response_received, response_sms_sid: @ticket.response_sms_sid, status: @ticket.status }
    assert_redirected_to ticket_path(assigns(:ticket))
  end

  test "should destroy ticket" do
    assert_difference('Ticket.count', -1) do
      delete :destroy, id: @ticket
    end

    assert_redirected_to tickets_path
  end
end
