class PhoneDirectoryEntriesController < ApplicationController
  # GET /phone_directory_entries
  # GET /phone_directory_entries.json
  def index
    @phone_directory_entries = PhoneDirectoryEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @phone_directory_entries }
    end
  end

  # GET /phone_directory_entries/1
  # GET /phone_directory_entries/1.json
  def show
    @phone_directory_entry = PhoneDirectoryEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @phone_directory_entry }
    end
  end

  # GET /phone_directory_entries/new
  # GET /phone_directory_entries/new.json
  def new
    @phone_directory_entry = PhoneDirectoryEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @phone_directory_entry }
    end
  end

  # GET /phone_directory_entries/1/edit
  def edit
    @phone_directory_entry = PhoneDirectoryEntry.find(params[:id])
  end

  # POST /phone_directory_entries
  # POST /phone_directory_entries.json
  def create
    @phone_directory_entry = PhoneDirectoryEntry.new(params[:phone_directory_entry])

    respond_to do |format|
      if @phone_directory_entry.save
        format.html { redirect_to @phone_directory_entry, notice: 'Phone directory entry was successfully created.' }
        format.json { render json: @phone_directory_entry, status: :created, location: @phone_directory_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @phone_directory_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /phone_directory_entries/1
  # PUT /phone_directory_entries/1.json
  def update
    @phone_directory_entry = PhoneDirectoryEntry.find(params[:id])

    respond_to do |format|
      if @phone_directory_entry.update_attributes(params[:phone_directory_entry])
        format.html { redirect_to @phone_directory_entry, notice: 'Phone directory entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @phone_directory_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_directory_entries/1
  # DELETE /phone_directory_entries/1.json
  def destroy
    @phone_directory_entry = PhoneDirectoryEntry.find(params[:id])
    @phone_directory_entry.destroy

    respond_to do |format|
      format.html { redirect_to phone_directory_entries_url }
      format.json { head :no_content }
    end
  end
end
