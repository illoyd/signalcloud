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
    if params[:complete]
      @organization.contact_address ||= Address.new
      @organization.billing_address ||= Address.new
    end
    respond_with @organization
  end

  # GET /organizations/1/edit
  def edit
    if params[:complete]
      @organization.build_contact_address if @organization.contact_address.nil?
      @organization.build_billing_address if @organization.billing_address.nil?
    end
    respond_with @organization
  end

  # POST /organizations
  # POST /organizations.json
  def create
    @organization.account_plan = AccountPlan.default
    flash[:success] = 'Your organization has been created.' if @organization.update_attributes(organization_params)
    respond_with @organization
  end

  # PUT /organizations/1
  # PUT /organizations/1.json
  def update
    flash[:success] = 'Your organization has been updated.' if @organization.update_attributes(organization_params)
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
