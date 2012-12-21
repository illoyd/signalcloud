require 'test_helper'

class Twilio::InboundSmsControllerTest < ActionController::TestCase

  def build_twilio_sms()
  end

  setup do
    @account = accounts(:test_account)
    assert_not_nil( @account )
  end
  
  test "should request, fail, then sign in, succeed, post a blank, fail, post a good answer, succeed" do
    # Should not authenticate
    post :create, {}
    assert_response :unauthorized

    # Should authenticate, but should fail when making a page request
    authenticate_with_http_digest @account.account_sid, @account.auth_token, DIGEST_REALM
    post :create
    assert_response :forbidden
    
    # Now, create one that actually works
    post :create, { }
    flunk 'Needs more details to create sms'
    assert_response :created
  end

  test "should authorise but fail without sms input" do
    # Should authenticate, but should fail when making a page request
    authenticate_with_http_digest @account.account_sid, @account.auth_token, DIGEST_REALM
    post :create
    assert_response :forbidden
  end  

  test "should create sms" do
    # Should not authenticate
    authenticate_with_http_digest @account.account_sid, @account.auth_token, DIGEST_REALM
    get :create, { }
    flunk 'Needs more details to create sms'
    assert_response :created
  end  

  test "should not be authorised (no credentials)" do
    # Should not authenticate
    get :create, {}
    assert_response :unauthorized
  end  

  test "should not be authorised (bad user, pass)" do
    # Test with both being bad, but right realm
    authenticate_with_http_digest 'not a real sid', 'not a real token', DIGEST_REALM
    post :create
    assert_response :unauthorized
  end

  test "should not be authorised (bad user)" do
    # Test with bad sid
    authenticate_with_http_digest 'not a real sid', @account.auth_token, DIGEST_REALM
    post :create
    assert_response :unauthorized
  end

  test "should not be authorised (bad pass)" do
    # Test with bad token
    authenticate_with_http_digest @account.account_sid, 'not a real token', DIGEST_REALM
    post :create
    assert_response :forbidden
  end

  test "should not be authorised (bad user, pass, realm)" do
    # Test with both being bad, but right realm
    authenticate_with_http_digest 'not a real sid', 'not a real token', 'another_realm'
    post :create
    assert_response :unauthorized
  end

  test "should not be authorised (bad user, realm)" do
    # Test with bad sid
    authenticate_with_http_digest 'not a real sid', @account.auth_token, 'another_realm'
    post :create
    assert_response :unauthorized
  end

  test "should not be authorised (bad pass, realm)" do
    # Test with bad token
    authenticate_with_http_digest @account.account_sid, 'not a real token', 'another_realm'
    post :create
    assert_response :unauthorized
  end

end
