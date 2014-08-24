class UsersController < ProtectedController
  
  respond_to :html, :json, :xml

  # Index authorisations
  before_action :assign_default_user_id, only: :show
  load_and_authorize_resource :organization
  load_and_authorize_resource through: :organization, shallow: true
  
  # GET /organization/1/users
  def index
    respond_with @organization, @users
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @shared_organizations = @user.organizations.accessible_by(current_ability)
    respond_with @user
  end

  def assign_default_user_id
    params[:id] = current_user.id if params[:id].blank?
  end

end
