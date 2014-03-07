class UsersController < ApplicationController
  
  respond_to :html, :json, :xml

  # before_filter :cannot_manage_organization_owner_roles, only: [:index]

  # Index authorisations
  load_and_authorize_resource :organization, only: :index
  load_and_authorize_resource through: :organization, only: :index
  
  # Other authorisations
  load_and_authorize_resource except: [:index]

  # GET /organization/1/users
  def index
    @user_role = UserRole.new( organization: @organization )
    respond_with @organization, @users
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @shared_organizations = @user.organizations.accessible_by(current_ability)
    respond_with @user
  end

  # GET /users/new
  # GET /users/new.json
  def new
    respond_with @user
  end

  # GET /users/1/edit
  def edit
    respond_with @user
  end

  # POST /users
  # POST /users.json
  def create
    flash[:notice] = 'User was successfully created.' if @user.update_attributes(user_params)
    respond_with @user
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    flash[:notice] = 'User was successfully updated.' if @user.update_attributes(user_params)
    respond_with @user
  end

end
