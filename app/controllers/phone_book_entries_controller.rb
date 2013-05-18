class PhoneBookEntriesController < ApplicationController

  load_and_authorize_resource
  before_filter :assign_organization

  respond_to :html, :json

  # POST /phone_book_entries
  # POST /phone_book_entries.json
  def create
    @phone_book_entry = @organization.phone_book_entries.build( params[:phone_book_entry] )
    if @phone_book_entry.save
      flash[:success] = 'Phone number was successfully added to phone book.'
    else
      flash[:error] = 'Oops! We errored.'
      flash[:validation_errors] = @phone_book_entry.errors.to_yaml
    end
    respond_with @phone_book_entry.phone_book
  end

  # DELETE /phone_book_entries/1
  # DELETE /phone_book_entries/1.json
  def destroy
   @phone_book_entry = @organization.phone_book_entries.find(params[:id])
   @phone_book = @phone_book_entry.phone_book
   @phone_book_entry.destroy
   
   respond_with @phone_book
  end

end
