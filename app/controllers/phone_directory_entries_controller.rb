class PhoneDirectoryEntriesController < ApplicationController

  load_and_authorize_resource

  respond_to :html, :json

  # POST /phone_directory_entries
  # POST /phone_directory_entries.json
  def create
    @phone_directory_entry = current_account.phone_directory_entries.build( params[:phone_directory_entry] )
    if @phone_directory_entry.save
      flash[:success] = 'Phone number was successfully added to phone directory.'
    else
      flash[:error] = 'Oops! We errored.'
      flash[:validation_errors] = @phone_directory_entry.errors.to_yaml
    end
    respond_with @phone_directory_entry.phone_directory
  end

  # DELETE /phone_directory_entries/1
  # DELETE /phone_directory_entries/1.json
  def destroy
   @phone_directory_entry = current_account.phone_directory_entries.find(params[:id])
   @phone_directory = @phone_directory_entry.phone_directory
   @phone_directory_entry.destroy
   
   respond_with @phone_directory
  end

end
