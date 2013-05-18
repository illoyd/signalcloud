class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :authenticate_user!
  
  # helper_method :current_organization
  helper_method :current_stencil
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  
  def assign_organization
    @organization = Organization.find(params[:organization_id])
    authorize! :show, @organization
  end

  def authenticate_organization!
    # Validate digest authentication
    results = authenticate_or_request_with_http_digest( DIGEST_REALM ) do |sid|
      (@organization = Organization.find_by_sid( sid )).try( :auth_token ) || false
    end
  end
  
  def authenticate_twilio!
    # If no organization given, kill immediately    
    if @organization.nil? || @organization == false
      head :unauthorized

    # Only continue processing if the organization was found
    else
      # Capture parameters
      signature_uri_without_auth = request.original_request_url
      signature_uri_with_auth = request.original_request_url @organization.sid, @organization.auth_token
      signature_params = request.post? ? request.request_parameters : request.query_parameters
      signature = request.headers.fetch( 'HTTP_X_TWILIO_SIGNATURE', 'NO HEADER GIVEN' )
      
      # FORBID if does not pass validation
      unless ( @organization.twilio_validator.validate( signature_uri_without_auth, signature_params, signature ) || @organization.twilio_validator.validate( signature_uri_with_auth, signature_params, signature ) )
        expected_signature_without_auth = @organization.twilio_validator.build_signature_for( signature_uri_without_auth, signature_params )
        expected_signature_with_auth = @organization.twilio_validator.build_signature_for( signature_uri_with_auth, signature_params )
        logger.error 'Could not auth Twilio ignoring digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_without_auth, signature_uri_without_auth, signature_params ]
        logger.error 'Could not auth Twilio using digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_with_auth, signature_uri_with_auth, signature_params ]
        head :forbidden
      end
    end
  end
  
  ##
  # Return the organization of the current request, based upon the request as well as user privileges.
  # Will default to the +current_user+ parent organization.
#   def current_organization
#     return Organization.find( session[:shadow_organization_id] ) if can?( :shadow, Organization ) && session.include?(:shadow_organization_id)
#     return current_user.organizations.first
#   end
  
  ##
  # Return the stencil of the current request, based upon the request and filtered to the current organization.
  # Will return nil if no stencil is specified in the request. This method is primarily intended to be used for 
  # nested resource requests.
  def current_stencil( use_default = true )
    return current_organization.stencils.find( params[:stencil_id] ) if params.include? :stencil_id
    return current_organization.primary_stencil if use_default
    return nil
  end

end
