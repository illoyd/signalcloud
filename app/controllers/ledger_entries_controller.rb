class LedgerEntriesController < ApplicationController

  respond_to :html, :json, :xml

  load_and_authorize_resource :organization
  load_and_authorize_resource through: :organization
  
  # GET /ledger_entries/1
  # GET /ledger_entries/1.json
  def show
    @ledger_entry = @organization.ledger_entries.find(params[:id])
    respond_with @organization, @ledger_entry
  end

end
