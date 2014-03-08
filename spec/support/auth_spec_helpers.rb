module AuthSpecHelpers

  ##
  # Convenience method for setting the Digest Authentication details.
  # To use, pass the username and password.
  # The method and target are used for the initial request to get the digest auth headers. These will be translated into 'get :index' for example.
  # The final 'header' parameter sets the request's authentication headers.
  def authenticate_with_http_digest(user, password, method = :get, target = :index, header = 'HTTP_AUTHORIZATION')
    @request.env[header] = encode_credentials(username: user, password: password, method: method, target: target)
  end

  ##
  # Shamelessly stolen from the Rails 4 test framework.
  # See https://github.com/rails/rails/blob/a3b1105ada3da64acfa3843b164b14b734456a50/actionpack/test/controller/http_digest_authentication_test.rb
  def encode_credentials(options)
    options.reverse_merge!(:nc => "00000001", :cnonce => "0a4f113b", :password_is_ha1 => false)
    password = options.delete(:password)

    # Perform unauthenticated request to retrieve digest parameters to use on subsequent request
    method = options.delete(:method) || 'GET'
    target = options.delete(:target) || :index

    case method.to_s.upcase
    when 'GET'
      get target
    when 'POST'
      post target
    end

    assert_response :unauthorized

    credentials = decode_credentials(@response.headers['WWW-Authenticate'])
    credentials.merge!(options)
    path_info = @request.env['PATH_INFO'].to_s
    uri = options[:uri] || path_info
    credentials.merge!(:uri => uri)
    @request.env["ORIGINAL_FULLPATH"] = path_info
    ActionController::HttpAuthentication::Digest.encode_credentials(method, credentials, password, options[:password_is_ha1])
  end

  ##
  # Also shamelessly stolen from the Rails 4 test framework.
  # See https://github.com/rails/rails/blob/a3b1105ada3da64acfa3843b164b14b734456a50/actionpack/test/controller/http_digest_authentication_test.rb
  def decode_credentials(header)
    ActionController::HttpAuthentication::Digest.decode_credentials(header)
  end

end
