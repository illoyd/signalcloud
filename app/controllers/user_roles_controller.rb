# params = { user_role: { email: 'ian.w.lloyd@gmail.com' } }
# current_user = User.find 1
# @organization = current_user.organizations.first

class UserRolesController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :assign_organization

  # POST /user_roles
  # POST /user_roles.json
  def create
  
    # Handle inviting a user if necessary
    if params[:user_role].include? :email
      email = params[:user_role][:email].chomp.downcase
      
      # Try to find the user in the database; if not found, invite
      user = User.find_by_email( email )
      if user.nil?
        first_name = params[:user_role].fetch(:first_name, 'Anonymous')
        last_name = params[:user_role].fetch(:last_name, 'Anonymous')
        user = User.invite!( {email: email, first_name: first_name, last_name: last_name}, current_user )
        user.save
      end
      
      # Update the passed parameters for this role
      params[:user_role][:user_id] = user.id
      params[:user_role].delete :email
    end
  
    params[:roles] ||= []
    @role = @organization.user_roles.build(params[:user_role])
    authorize! :create, @role
    
    flash[:notice] = "Role was added successfully." if @role.save
    redirect_to organization_users_path( @organization )
  end
  
  # POST /user_roles/1
  # POST /user_roles/1.json
  def update
    @role = UserRole.find(params[:id])
    authorize! :update, @role
    
    params[:roles] ||= []

    flash[:notice] = "Role was updated successfully." if @role.update_attributes(params[:user_role])
    redirect_to organization_users_path( @organization )
  end

  # DELETE /user_roles/1
  # DELETE /user_roles/1.json
  def destroy
    @role = @organization.user_roles.find(params[:id])
    authorize! :destroy, @role

    flash[:notice] = "Role was removed successfully." if @role.destroy
    redirect_to organization_users_path( @organization )
  end

end
