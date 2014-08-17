# params = { user_role: { email: 'ian.w.lloyd@gmail.com' } }
# current_user = User.find 1
# @organization = current_user.organizations.first

class UserRolesController < ApplicationController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  before_filter :cannot_manage_organization_owner_roles
  before_filter :load_new_user_role, only: [ :new, :create ]
  load_and_authorize_resource through: :organization

  def load_new_user_role
    @user_role = @organization.user_roles.build()
    @user_role.assign_attributes( user_role_params ) if params.include? :user_role
    @user_role
  end
  
  # POST /user_roles
  # POST /user_roles.json
  def create
  
    # Try to find the user in the database; if not found, invite
    user = User.find_by_email( user_role_user_params[:email] )
    if user.nil?
      user = User.invite!( user_role_user_params, current_user )
    end
    
    # If the user is already in the current organization, stop
    if @organization.users.include? user
      flash[:notice] = "%s (%s) is already a member of this organization." % [ user.nickname, user.email ]
      redirect_to organization_users_path( @organization ) and return
    end
    
    # Abort if errors given
    unless user.save
      @user_role.errors.add( :email, 'cannot be blank.' )
      flash[:error] = "There were some issues with inviting the user. (Is the email valid?)"

    # Update the passed parameters for this role
    else
      @user_role.user = user
      flash[:success] = "%s (%s) was invited successfully." % [ @user_role.user.nickname, @user_role.user.email ] if @user_role.update_attributes(user_role_params)
    end

    redirect_to organization_users_path( @organization )
  end
  
  # POST /user_roles/1
  # POST /user_roles/1.json
  def update
    flash[:success] = "%s (%s) roles were updated successfully." % [ @user_role.user.nickname, @user_role.user.email ] if @user_role.update_attributes(user_role_params)
    redirect_to organization_users_path( @organization )
  end

  # DELETE /user_roles/1
  # DELETE /user_roles/1.json
  def destroy
    flash[:success] = "%s (%s) was uninvited from the team." % [ @user_role.user.nickname, @user_role.user.email ] if @user_role.destroy
    redirect_to organization_users_path( @organization )
  end

end
