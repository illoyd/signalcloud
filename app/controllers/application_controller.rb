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
      signature_uri_without_auth = request.original_request_url
      signature_uri_with_auth = request.original_request_url @account.account_sid, @account.auth_token
      signature_params = request.post? ? request.request_parameters : request.query_parameters
      signature = request.headers.fetch( 'HTTP_X_TWILIO_SIGNATURE', 'NO HEADER GIVEN' )
      
      # FORBID if does not pass validation
      unless ( @account.twilio_validator.validate( signature_uri_without_auth, signature_params, signature ) || @account.twilio_validator.validate( signature_uri_with_auth, signature_params, signature ) )
        expected_signature_without_auth = @account.twilio_validator.build_signature_for( signature_uri_without_auth, signature_params )
        expected_signature_with_auth = @account.twilio_validator.build_signature_for( signature_uri_with_auth, signature_params )
        logger.error 'Could not auth Twilio ignoring digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_without_auth, signature_uri_without_auth, signature_params ]
        logger.error 'Could not auth Twilio using digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_with_auth, signature_uri_with_auth, signature_params ]
        head :forbidden
      end
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
  # Return the stencil of the current request, based upon the request and filtered to the current account.
  # Will return nil if no stencil is specified in the request. This method is primarily intended to be used for 
  # nested resource requests.
  def current_stencil( use_default = true )
    return current_account.stencils.find( params[:stencil_id] ) if params.include? :stencil_id
    return current_account.primary_stencil if use_default
    return nil
  end

end
