class BoxesController < ApplicationController

  respond_to :html, :json, :xml, :xlsx
  load_and_authorize_resource :organization
  before_filter :load_new_box, only: [ :new, :create ]
  load_and_authorize_resource through: :organization
  
  def load_new_box
    @box = @organization.boxes.build()
    @box.assign_attributes( box_params ) if params.include? :box
    @box
  end

  # GET /boxes
  # GET /boxes.json
  def index
    respond_with @organization, @boxes
  end

  # GET /boxes/1
  # GET /boxes/1.json
  def show
    respond_with @organization, @box
  end

  # GET /boxes/new
  # GET /boxes/new.json
  def new
    respond_with @organization, @box
  end

  # GET /boxes/1/edit
  def edit
    respond_with @organization, @box
  end

  # POST /boxes
  # POST /boxes.json
  def create
    flash[:success] = 'Your new box has been created.' if @box.update_attributes(box_params)
    respond_with @organization, @box
  end

  # PATCH/PUT /boxes/1
  # PATCH/PUT /boxes/1.json
  def update
    flash[:success] = 'Your box has been updated.' if @box.update_attributes(box_params)
    respond_with @organization, @box
  end

  # DELETE /boxes/1
  # DELETE /boxes/1.json
  def destroy
    flash[:success] = 'Your box has been deleted.' if @box.destroy
    respond_with @organization, @box
  end

  private

    # Use this method to whitelist the permissible parameters. Example:
    # params.require(:person).permit(:name, :age)
    # Also, you can specialize this method with per-user checking of permissible attributes.
    def box_params
      params.require(:box).permit( :label, :stencil_id, :start_at )
    end
end
