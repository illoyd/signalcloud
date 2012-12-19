require 'test_helper'

class Twilio::InboundSmsControllerTest < ActionController::TestCase

  setup do
    @account = accounts(:test_account)
    assert_not_nil( @account )
  end

  test "should post inbound_call (unauthorised)" do
    # Should not authenticate
    post :show, {}
    assert_response 401
  end  

  test "should create sms (bad credentials)" do
    # Test with both being bad, but right realm
    authenticate_with_http_digest 'not a real sid', 'not a real token', DIGEST_REALM
    post :show
    assert_response 401

    # Test with bad sid
    authenticate_with_http_digest 'not a real sid', @account.auth_token, DIGEST_REALM
    post :show
    assert_response 401

    # Test with bad token
    authenticate_with_http_digest @account.account_sid, 'not a real token', DIGEST_REALM
    post :show
    assert_response 401
  end

  test "should create sms (bad realm)" do
    # Test with both being bad, but right realm
    authenticate_with_http_digest 'not a real sid', 'not a real token', 'another_realm'
    post :show
    assert_response 401

    # Test with bad sid
    authenticate_with_http_digest 'not a real sid', @account.auth_token, 'another_realm'
    post :show
    assert_response 401

    # Test with bad token
    authenticate_with_http_digest @account.account_sid, 'not a real token', 'another_realm'
    post :show
    assert_response 401
  end

  test "should create sms (authorised but not valid)" do
    # Should authenticate, but should fail when making a page request
    authenticate_with_http_digest @account.account_sid, @account.auth_token, DIGEST_REALM
    post :show
    assert_response 403
  end

  test "should get inbound_sms (unauthorised)" do
    get :inbound_sms
    assert_response 401
  end

end
