class TicketsController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :setup_account_and_stencilb

  load_and_authorize_resource
  skip_authorize_resource only: [:new, :create]
  
  def setup_account_and_stencilb
    @account = current_account()
    @stencil = current_stencilb(false)
  end
  
  # GET /tickets
  # GET /tickets.json
  def index
    if @stencil.nil?
      redirect_to stencil_tickets_path(current_stencilb(true))
      return
    end

    @multistencil = @stencil.nil?
    if !@multistencil
      @tickets = @tickets.where( stencil_id: @stencil.id )
    end
    
    unless params[:status].nil?
      @tickets = @tickets.where( status: params[:status] )
    end
    
    # Add pagination
    @tickets = @tickets.page(params[:page])

    respond_with @tickets
  end

  # GET /tickets/1
  # GET /tickets/1.json
  def show
    # @ticket = ( @stencil.nil? ? @account : @stencil ).tickets.find(params[:id])
    respond_with @ticket
  end

  # GET /tickets/new
  # GET /tickets/new.json
  def new
    @ticket = @stencil.open_ticket({})
    authorize!( :new, @ticket )
  end

  # GET /tickets/1/edit
  #   def edit
  #     @ticket = ( @stencil.nil? ? @account : @stencil ).tickets.find(params[:id])
  #   end

  # POST /tickets
  # POST /tickets.json
  def create
    # @ticket = ( @stencil.nil? ? @account : @stencil ).tickets.create( params[:ticket] )
    @ticket = @stencil.open_ticket( params[:ticket] )
    authorize!( :create, @ticket )

    if @ticket.save
      JobTools.enqueue SendTicketChallengeJob.new( @ticket.id )
      flash[:success] = 'The ticket has been successfully started.'
    end
    respond_with @ticket
  end

  # PUT /tickets/1
  # PUT /tickets/1.json
  #   def update
  #     @ticket = ( @stencil.nil? ? @account : @stencil ).tickets.find(params[:id])
  # 
  #     respond_to do |format|
  #       if @ticket.update_attributes(params[:ticket])
  #         format.html { redirect_to @ticket, notice: 'Ticket was successfully updated.' }
  #         format.json { head :no_content }
  #       else
  #         format.html { render action: "edit" }
  #         format.json { render json: @ticket.errors, status: :unprocessable_entity }
  #       end
  #     end
  #   end

  # DELETE /tickets/1
  # DELETE /tickets/1.json
  #   def destroy
  #     @ticket = ( @stencil.nil? ? @account : @stencil ).tickets.find(params[:id])
  #     @ticket.destroy
  # 
  #     respond_to do |format|
  #       format.html { redirect_to tickets_url }
  #       format.json { head :no_content }
  #     end
  #   end
  
  ##
  # Allow 'forcing' the status of a ticket.
  def force
    
  end

end
