class ApplicationController < ActionController::Base
  protect_from_forgery

  def authenticate_api!
  
    # Validate digest authentication
    account = nil
    results = authenticate_or_request_with_http_digest( DIGEST_REALM ) do |sid|
      (account = Account.find_by_account_sid( sid )).try( :auth_token ) # || false
    end
    
    puts 'Results? ' + results.to_s

    return results ? account : false
  end
  
  def authenticate_twilio!
  
    account = authenticate_api!

    # If no account given, kill immediately    
    if account.nil? or account == false
      return false #head :unauthorized

    # Only process this step if the account was found
    else
      # Capture parameters
      v_uri = request.url
      v_params = request.post? ? request.request_parameters : request.query_parameters
      v_header = request.headers['HTTP_X_TWILIO_SIGNATURE']
    
      # FORBID if does not pass validation
      head :forbidden unless Twilio::Util::RequestValidator.new( account.twilio_auth_token ).validate v_uri, v_params, v_header
    end
    
    return account

  end

end
