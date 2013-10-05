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

  protected
  
  def organization_params
    # Re-used address attributes
    address_attributes = [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country, :organization_id ]
    
    # General organization attributes
    organization_attributes = [
      :label, :icon, :description, :vat_name, :vat_number, :purchase_order,
      contact_address_attributes: address_attributes,
      billing_address_attributes: address_attributes
    ]
    
    # Additional attributes if current user is an administrator
    #organization_attributes += [ :account_plan, :account_plan_id ] if current_user.system_admin
    
    # require and permit
    # params.require(:organization).permit(organization_attributes)
    params.require(:organization).permit( :label, :icon, :description )
  end

  def stencil_params
    params.require(:stencil).permit( :label, :primary, :phone_book_id, :seconds_to_live, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :question, :description, :webhook_uri )
  end

  def phone_book_params
    params.require(:phone_book).permit( :description, :label )
  end

  def conversation_params
    params.require(:conversation).permit( :seconds_to_live, :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :expires_at, :webhook_uri )
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
