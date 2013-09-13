class PhoneBookEntriesController < ApplicationController

  respond_to :html, :json, :xml
  load_and_authorize_resource :organization
  before_filter :load_new_phone_book_entry, only: [ :new, :create ]
  load_and_authorize_resource through: :organization
  
  def load_new_phone_book_entry
    @phone_book_entry = PhoneBookEntry.new
    @phone_book_entry.assign_attributes( phone_book_entry_params ) if params.include? :phone_book_entry
  end

  # POST /phone_book_entries
  # POST /phone_book_entries.json
  def create
    if @phone_book_entry.save
      flash[:success] = 'Phone number was successfully added to this phone book.'
    end
    respond_with @organization, @phone_book_entry.phone_book
  end

  # DELETE /phone_book_entries/1
  # DELETE /phone_book_entries/1.json
  def destroy
    if @phone_book_entry.destroy
      flash[:success] = 'Phone number was removed from this phone book.'
    end
    respond_with @organization, @phone_book_entry.phone_book
  end

end
