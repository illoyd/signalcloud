class StencilsController < ApplicationController
  
  respond_to :html, :json, :xml
  load_and_authorize_resource

  # GET /stencils
  # GET /stencils.json
  def index
    @stencils = current_organization.stencils.order('label')
    
    # Apply an active/inactive filter if requested
    if ( params.include? :active_filter )
      @stencils = @stencils.where( active: params[:active_filter] )
    end

    respond_with @stencils
  end

  # GET /stencils/1
  # GET /stencils/1.json
  def show
    @stencil = current_organization.stencils.find( params[:id] )

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @stencil }
    end
  end

  # GET /stencils/new
  # GET /stencils/new.json
  def new
    @stencil = current_organization.stencils.build
#    respond_with @stencil
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @stencil }
    end
  end

  # GET /stencils/1/edit
  def edit
    @stencil = current_organization.stencils.find( params[:id] )
  end

  # POST /stencils
  # POST /stencils.json
  def create
    @stencil = current_organization.stencils.build( params[:stencil] )

    respond_to do |format|
      if @stencil.save
        format.html { redirect_to @stencil, notice: 'Stencil was successfully created.' }
        format.json { render json: @stencil, status: :created, location: @stencil }
      else
        format.html { render action: "new" }
        format.json { render json: @stencil.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /stencils/1
  # PUT /stencils/1.json
  def update
    @stencil = current_organization.stencils.find( params[:id] )

    respond_to do |format|
      if @stencil.update_attributes(params[:stencil])
        format.html { redirect_to @stencil, notice: 'Stencil was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @stencil.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stencils/1
  # DELETE /stencils/1.json
  def destroy
    @stencil = current_organization.stencils.find( params[:id] )
    @stencil.destroy

    respond_to do |format|
      format.html { redirect_to stencils_url }
      format.json { head :no_content }
    end
  end

end
