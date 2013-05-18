class OrganizationsController < ApplicationController

  respond_to :html, :json, :xml
  load_and_authorize_resource
  
  # GET /organizations
  # GET /organizations.json
  def index
    respond_with @organizations
  end

  # GET /organizations/1
  # GET /organizations/1.json
  def show
    respond_with @organization
  end

  # GET /organizations/new
  # GET /organizations/new.json
  #   def new
  #     @organization = Organization.new
  #   end

  # GET /organizations/1/edit
  def edit
    respond_with @organization
  end

  # POST /organizations
  # POST /organizations.json
  #   def create
  #     @organization = Organization.new( params[:organization] )
  #     if @organization.save
  #       flash[:success] = 'Your organization has been created.'
  #     end
  #     respond_with @organization
  #   end

  # PUT /organizations/1
  # PUT /organizations/1.json
  def update
    
    # Delete the sensitive settings unless system admin
    unless current_user.system_admin
      params[:organization].remove( :account_plan_id ) 
      params[:organization].remove( :account_plan ) 
    end

    # Save
    if @organization.update_attributes(params[:organization])
      flash[:success] = 'Your organization has been updated.'
    end
    respond_with @organization
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.json
  #   def destroy
  #     #@organization = current_organization
  #     @organization.destroy
  #     flash[:alert] = "Successfully destroyed organization."
  #     respond_with(@organization)
  #   end
  
end
