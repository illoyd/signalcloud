class OrganizationsController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :load_new_organization, only: [ :new, :create ]
  load_and_authorize_resource
  
  def load_new_organization
    @organization = Organization.new
    @organization.user_roles.build(user_id: current_user.id, roles: UserRole::ROLES) if current_user
    @organization
  end
  
  # GET /organizations
  # GET /organizations.json
  def index
    @organizations = @organizations.order(:label).page(params[:page])
    respond_with @organizations
  end

  # GET /organizations/1
  # GET /organizations/1.json
  def show
    respond_with @organization
  end

  # GET /organizations/new
  # GET /organizations/new.json
  def new
    respond_with @organization
  end

  # GET /organizations/1/edit
  def edit
    respond_with @organization
  end

  # POST /organizations
  # POST /organizations.json
  def create
    @organization.account_plan = AccountPlan.default
    @organization.owner = current_user
    flash[:success] = 'Your organization has been created.' if @organization.update(organization_params)
    respond_with @organization
  end

  # PUT /organizations/1
  # PUT /organizations/1.json
  def update
    flash[:success] = 'Your organization has been updated.' if @organization.update(organization_params)
    respond_with @organization
  end
  
  # POST /organizations/1/upgrade
  def upgrade
    if @organization.can_upgrade?
      begin
        @organization.upgrade!
        flash[:success] = 'Congrats! Your organization has been upgraded.' if @organization.save
      rescue Workflow::TransitionHalted => ex
        flash[:error] = ex.message
      end
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
