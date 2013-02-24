class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :authenticate_user!
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
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
      v_uri = request.original_request_url @account.account_sid, @account.auth_token
      v_params = request.post? ? request.request_parameters : request.query_parameters
      v_header = request.headers.fetch( 'HTTP_X_TWILIO_SIGNATURE', 'NO HEADER GIVEN' )
      
      #v_uri = 'http://%s:%s@localhost:5000%s' % [ @account.account_sid, @account.auth_token, request.path ]
      v_params = env['rack.request.form_hash']
      v_header = env['HTTP_X_TWILIO_SIGNATURE']
      
      response.headers['v_uri'] = v_uri
#       response.headers['v_params'] = v_params.to_s
#       response.headers['v_header'] = v_header.to_s
#       response.headers['v_header_calc'] = @account.twilio_validator.build_signature_for( v_uri, v_params )

#       print "authenticate_twilio!\n"
#       #print "  Base URL: %s\n" % request.url
#       print "  New! URL: %s\n" % request.original_request_url()
#       #print "  Params: Q:%i, R:%i, All:%i\n" % [ request.query_parameters.size, request.request_parameters.size, params.size ]
#       #print "  Method: %s\n" % request.request_method
#       print "  Given: %s\n" % v_header
#       print "  Expected: %s\n" % @account.twilio_validator.build_signature_for( request.original_request_url, v_params )
#       print "  Request parameters:"
#       pp v_params
#       #print "  ALL parameters:"
#       #pp params
    
      # FORBID if does not pass validation
      head :forbidden unless @account.twilio_validator.validate( v_uri, v_params, v_header )
    end
  end
  
  ##
  # Return the account of the current request, based upon the request as well as user privileges.
  # Will default to the +current_user+ parent account.
  def current_account
    return Account.find( session[:shadow_account_id] ) if current_user.can_shadow_account? && session.include?(:shadow_account_id)
    return current_user.account
  end
  
  ##
  # Return the appliance of the current request, based upon the request and filtered to the current account.
  # Will return nil if no appliance is specified in the request. This method is primarily intended to be used for 
  # nested resource requests.
  def current_appliance( use_default = true )
    return current_account.appliances.find( params[:appliance_id] ) if params.include? :appliance_id
    return current_account.primary_appliance if use_default
    return nil
  end

end
