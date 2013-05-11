class UsersController < ApplicationController
  
  load_and_authorize_resource

  # GET /users
  # GET /users.json
  def index
    @users = current_organization.users #.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = current_organization.users.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = current_organization.users.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = current_organization.users.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = current_organization.users.build(params[:user])

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
    @user = current_organization.users.find(params[:id])

    if current_user.is_organization_administrator?
      params[:user][:roles] ||= []
      params[:user][:roles] << :super_user if ( @user.id == current_user.id and @user.is_super_user? )
      params[:user][:roles] << :organization_administrator if ( @user.id == current_user.id and @user.is_organization_administrator? )
      params[:user][:roles] = params[:user][:roles].keep_if{ |entry| User::ROLES.include?( (entry.to_sym rescue nil) ) }.map{ |entry| entry.to_sym }.uniq
    else
      params[:user].remove(:roles)
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
    @user = current_organization.users.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
