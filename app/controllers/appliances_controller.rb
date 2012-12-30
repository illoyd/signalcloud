class AppliancesController < ApplicationController
  
  respond_to :html, :json, :xml
  load_and_authorize_resource

  # GET /appliances
  # GET /appliances.json
  def index
    @appliances = current_account.appliances

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @appliances }
    end
  end

  # GET /appliances/1
  # GET /appliances/1.json
  def show
    @appliance = current_account.appliances.find( params[:id] )

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @appliance }
    end
  end

  # GET /appliances/new
  # GET /appliances/new.json
  def new
    @appliance = current_account.appliances.build
#    respond_with @appliance
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @appliance }
    end
  end

  # GET /appliances/1/edit
  def edit
    @appliance = current_account.appliances.find( params[:id] )
  end

  # POST /appliances
  # POST /appliances.json
  def create
    @appliance = current_account.appliances.build( params[:appliance] )

    respond_to do |format|
      if @appliance.save
        format.html { redirect_to @appliance, notice: 'Appliance was successfully created.' }
        format.json { render json: @appliance, status: :created, location: @appliance }
      else
        format.html { render action: "new" }
        format.json { render json: @appliance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /appliances/1
  # PUT /appliances/1.json
  def update
    @appliance = current_account.appliances.find( params[:id] )

    respond_to do |format|
      if @appliance.update_attributes(params[:appliance])
        format.html { redirect_to @appliance, notice: 'Appliance was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @appliance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /appliances/1
  # DELETE /appliances/1.json
  def destroy
    @appliance = current_account.appliances.find( params[:id] )
    @appliance.destroy

    respond_to do |format|
      format.html { redirect_to appliances_url }
      format.json { head :no_content }
    end
  end
end
