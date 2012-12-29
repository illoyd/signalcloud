class TicketsController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :setup_account_and_appliance
  
  def setup_account_and_appliance
    @account = current_account()
    @appliance = current_appliance(false)
  end
  
  # GET /tickets
  # GET /tickets.json
  def index
    @tickets = ( @appliance.nil? ? @account : @appliance ).tickets.all

    respond_with @tickets
  end

  # GET /tickets/1
  # GET /tickets/1.json
  def show
    @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ticket }
    end
  end

  # GET /tickets/new
  # GET /tickets/new.json
  def new
    @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ticket }
    end
  end

  # GET /tickets/1/edit
  def edit
    @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.find(params[:id])
  end

  # POST /tickets
  # POST /tickets.json
  def create
    # @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.create( params[:ticket] )
    @ticket = @appliance.open_ticket( params[:ticket] )

    respond_to do |format|
      if @ticket.save
        format.html { redirect_to @ticket, notice: 'Ticket was successfully created.' }
        format.json { render json: @ticket, status: :created, location: @ticket }
      else
        format.html { render action: "new" }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tickets/1
  # PUT /tickets/1.json
  def update
    @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.find(params[:id])

    respond_to do |format|
      if @ticket.update_attributes(params[:ticket])
        format.html { redirect_to @ticket, notice: 'Ticket was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tickets/1
  # DELETE /tickets/1.json
  def destroy
    @ticket = ( @appliance.nil? ? @account : @appliance ).tickets.find(params[:id])
    @ticket.destroy

    respond_to do |format|
      format.html { redirect_to tickets_url }
      format.json { head :no_content }
    end
  end
end
