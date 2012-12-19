class PhoneDirectoriesController < ApplicationController
  # GET /phone_directories
  # GET /phone_directories.json
  def index
    @phone_directories = PhoneDirectory.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @phone_directories }
    end
  end

  # GET /phone_directories/1
  # GET /phone_directories/1.json
  def show
    @phone_directory = PhoneDirectory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @phone_directory }
    end
  end

  # GET /phone_directories/new
  # GET /phone_directories/new.json
  def new
    @phone_directory = PhoneDirectory.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @phone_directory }
    end
  end

  # GET /phone_directories/1/edit
  def edit
    @phone_directory = PhoneDirectory.find(params[:id])
  end

  # POST /phone_directories
  # POST /phone_directories.json
  def create
    @phone_directory = PhoneDirectory.new(params[:phone_directory])

    respond_to do |format|
      if @phone_directory.save
        format.html { redirect_to @phone_directory, notice: 'Phone directory was successfully created.' }
        format.json { render json: @phone_directory, status: :created, location: @phone_directory }
      else
        format.html { render action: "new" }
        format.json { render json: @phone_directory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /phone_directories/1
  # PUT /phone_directories/1.json
  def update
    @phone_directory = PhoneDirectory.find(params[:id])

    respond_to do |format|
      if @phone_directory.update_attributes(params[:phone_directory])
        format.html { redirect_to @phone_directory, notice: 'Phone directory was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @phone_directory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_directories/1
  # DELETE /phone_directories/1.json
  def destroy
    @phone_directory = PhoneDirectory.find(params[:id])
    @phone_directory.destroy

    respond_to do |format|
      format.html { redirect_to phone_directories_url }
      format.json { head :no_content }
    end
  end
end
