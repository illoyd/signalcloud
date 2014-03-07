class StencilsController < ApplicationController
  
  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  before_filter :load_new_stencil, only: [ :new, :create ]
  load_and_authorize_resource through: :organization

  def load_new_stencil
    @stencil = Stencil.new( organization_id: @organization.id, phone_book_id: @organization.phone_books.first.id )
    @stencil.assign_attributes( stencil_params ) if params.include? :stencil
    @stencil
  end
  
  # GET /stencils
  # GET /stencils.json
  def index
    # Apply an active/inactive filter if requested
    if ( params.include? :active_filter )
      @stencils = @stencils.where( active: params[:active_filter] )
    end

    respond_with @organization, @stencils
  end

  # GET /stencils/1
  # GET /stencils/1.json
  def show
    respond_with @organization, @stencil
  end

  # GET /stencils/new
  # GET /stencils/new.json
  def new
    respond_with @organization, @stencil
  end

  # GET /stencils/1/edit
  def edit
    respond_with @organization, @stencil
  end

  # POST /stencils
  # POST /stencils.json
  def create
    flash[:success] = 'Your new stencil has been saved.' if @stencil.update_attributes(stencil_params)
    respond_with @organization, @stencil
  end

  # PUT /stencils/1
  # PUT /stencils/1.json
  def update
    flash[:success] = 'Your stencil has been updated.' if @stencil.update_attributes(stencil_params)
    respond_with @organization, @stencil
  end

  # DELETE /stencils/1
  # DELETE /stencils/1.json
  def destroy
    flash[:success] = 'Your stencil has been deleted.' if @stencil.destroy
    respond_with @organization, @stencil
  end

end
