class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_stencil
  
  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      session[:next] = request.fullpath
      redirect_to sign_in_url, :alert => "Please sign in to continue."
    else
      if request.env["HTTP_REFERER"].present?
        redirect_to :back, :alert => exception.message
      else
        redirect_to root_url, :alert => exception.message
      end
    end
  end
  
  def assign_organization
    @organization = Organization.find(params[:organization_id])
    authorize! :show, @organization
  end
  
  ##
  # Authenticate the organisation using HTTP Basic.
  def authenticate_organization_using_basic!
    authenticate_or_request_with_http_basic do |sid, token|
      (@organization = Organization.find_by( sid: sid )).try( :auth_token ) == token
    end
  end

  ##
  # Authenticate the organisation using HTTP Digest.
  def authenticate_organization_using_digest!
    authenticate_or_request_with_http_digest do |sid|
      (@organization = Organization.find_by( sid: sid )).try( :auth_token )
    end
  end
  
  alias_method :authenticate_organization!, :authenticate_organization_using_digest!

  ##
  # Return the stencil of the current request, based upon the request and filtered to the current organization.
  # Will return nil if no stencil is specified in the request. This method is primarily intended to be used for 
  # nested resource requests.
  def current_stencil( use_default = true )
    return current_organization.stencils.find( params[:stencil_id] ) if params.include? :stencil_id
    return current_organization.primary_stencil if use_default
    return nil
  end

  protected
  
  def configure_permitted_parameters
    # Inject new parameters for accepting invitations
    devise_parameter_sanitizer.for(:accept_invitation).concat [:name, :nickname]
    
    # Inject new paramters for inviting a user
    # devise_parameter_sanitizer.for(:invite).concat [ :organization_id, user_role: [ roles: [] ] ]

    # Signing up
    devise_parameter_sanitizer.for(:sign_up).concat [:name, :nickname]
    
    # Updating profile
    devise_parameter_sanitizer.for(:account_update).concat [:name, :nickname]
  end

  def organization_params
    params.require(:organization).permit( :label, :icon, :description, :vat_name, :vat_number, :purchase_order, :use_billing_as_contact_address, :contact_first_name, :contact_last_name, :contact_email, :contact_work_phone, :contact_line1, :contact_line2, :contact_city, :contact_region, :contact_postcode, :contact_country, :billing_first_name, :billing_last_name, :billing_email, :billing_work_phone, :billing_line1, :billing_line2, :billing_city, :billing_region, :billing_postcode, :billing_country )
  end

  def stencil_params
    params.require(:stencil).permit( :label, :primary, :phone_book_id, :seconds_to_live, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :question, :description, :webhook_uri, :active )
  end

  def phone_book_params
    params.require(:phone_book).permit( :description, :label, :active )
  end
  
  def phone_number_params
    params.require(:phone_number).permit(:unsolicited_sms_action, :unsolicited_sms_message, :unsolicited_call_action, :unsolicited_call_message, :unsolicited_call_voice, :unsolicited_call_language)
  end

  def buy_phone_number_params
    params.require(:phone_number).permit(:number)
  end

  def conversation_params
    params.require(:conversation).permit( :seconds_to_live, :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number_id, :question, :customer_number, :expires_at, :webhook_uri )
  end
  
  def phone_book_entry_params
    params.require(:phone_book_entry).permit( :country, :phone_number_id, :phone_book_id )
  end
  
  def user_role_params
    params.require(:user_role).permit( roles: [] )
  end
  
  def new_user_role_params
    params.require(:user_role).permit( :user_id, roles: [] )
  end
  
  def user_role_user_params
    params.require(:user_role).permit( :email, :nickname, :name )
  end
  
  def cannot_manage_organization_owner_roles
    if @organization
      current_ability.cannot [:edit, :destroy], UserRole, { organization_id: @organization.id, user_id: @organization.owner_id }
    end
  end

end
