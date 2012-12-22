class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :create_temp_user
  
  def create_temp_user
    @user = User.first
  end

  def authenticate_account!
    # Validate digest authentication
    results = authenticate_or_request_with_http_digest( DIGEST_REALM ) do |sid|
      (@account = Account.find_by_account_sid( sid )).try( :auth_token ) || false
    end
  end
  
  def authenticate_twilio!
    # If no account given, kill immediately    
    if @account.nil? || @account == false
      head :unauthorized

    # Only continue processing if the account was found
    else
      # Capture parameters
      v_params = request.post? ? request.request_parameters : request.query_parameters
      v_header = request.headers.fetch( 'HTTP_X_TWILIO_SIGNATURE', 'NO HEADER GIVEN' )

      #print "authenticate_twilio!\n"
      #print "  Base URL: %s\n" % request.url
      #print "  New! URL: %s\n" % request.original_request_url()
      #print "  Params: Q:%i, R:%i, All:%i\n" % [ request.query_parameters.size, request.request_parameters.size, params.size ]
      #print "  Method: %s\n" % request.request_method
      #print "  Given: %s\n" % v_header
      #print "  Expected: %s\n" % @account.twilio_validator.build_signature_for( request.original_request_url, v_params )
      #print "  Request parameters:"
      #pp v_params
      #print "  ALL parameters:"
      #pp params
    
      # FORBID if does not pass validation
      head :forbidden unless @account.twilio_validator.validate( request.original_request_url, v_params, v_header )
    end
  end

end
