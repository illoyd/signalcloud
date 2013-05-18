class UsersController < ApplicationController
  
  # load_and_authorize_resource
  respond_to :html, :json, :xml
  before_filter :assign_organization

  # GET /users
  # GET /users.json
  def index
    @users = @organization.users
    authorize! :index, User
    respond_with @users
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = @organization.users.find(params[:id])
    authorize! :show, @user
    respond_with @user
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = @organization.users.build
    authorize! :new, @user
  end

  # GET /users/1/edit
  def edit
    @user = @organization.users.find(params[:id])
    authorize! :edit, @user
  end

  # POST /users
  # POST /users.json
  def create
    @user = @organization.users.build(params[:user])
    authorize! @user

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = @organization.users.find(params[:id])
    authorize! :update, @user

    if current_user.roles_for(@organization).is_organization_administrator?
      params[:roles] ||= []
      params[:roles] << :organization_administrator if ( @user.id == current_user.id and @user.roles_for(@organization).is_organization_administrator? )
      params[:roles] = params[:roles].keep_if{ |entry| UserRole::ROLES.include?( (entry.to_sym rescue nil) ) }.map{ |entry| entry.to_sym }.uniq
      user_roles = @user.roles_for(@organization)
      user_roles.roles = params[:roles]
      user_roles.save
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = @organization.users.find(params[:id])
    authorize! :destroy, @user

    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
