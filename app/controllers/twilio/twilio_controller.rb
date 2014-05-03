class Twilio::TwilioController < ApplicationController

  respond_to :xml
  before_filter :authenticate_organization!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  
  def show
    head :ok
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
      gateway = @organization.communication_gateway_for :twilio
      unless ( gateway.twilio_validator.validate( signature_uri_without_auth, signature_params, signature ) || gateway.twilio_validator.validate( signature_uri_with_auth, signature_params, signature ) )
        expected_signature_without_auth = gateway.twilio_validator.build_signature_for( signature_uri_without_auth, signature_params )
        expected_signature_with_auth = gateway.twilio_validator.build_signature_for( signature_uri_with_auth, signature_params )
        logger.error 'Could not auth Twilio ignoring digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_without_auth, signature_uri_without_auth, signature_params ]
        logger.error 'Could not auth Twilio using digest! Given %s, expected %s. Using URI %s and POST %s.' % [ signature, expected_signature_with_auth, signature_uri_with_auth, signature_params ]
        head :forbidden
      end
    end
  end

end
