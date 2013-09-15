class LedgerEntriesController < ApplicationController

  load_and_authorize_resource
  before_filter :assign_organization, :assign_invoice
  
  # GET /ledger_entries
  # GET /ledger_entries.json
  def index
  
    @ledger_entries = if @invoice
        @invoice.ledger_entries
      else
        @organization.ledger_entries.uninvoiced
      end
      
    # Apply pagination
    @ledger_entries = @ledger_entries.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ledger_entries }
    end
  end

  # GET /ledger_entries/1
  # GET /ledger_entries/1.json
  def show
    @ledger_entry = @organization.ledger_entries.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ledger_entry }
    end
  end

  # GET /ledger_entries/new
  # GET /ledger_entries/new.json
#   def new
#     @ledger_entry = LedgerEntry.new
# 
#     respond_to do |format|
#       format.html # new.html.erb
#       format.json { render json: @ledger_entry }
#     end
#   end

  # GET /ledger_entries/1/edit
#   def edit
#     @ledger_entry = LedgerEntry.find(params[:id])
#   end

  # POST /ledger_entries
  # POST /ledger_entries.json
#   def create
#     @ledger_entry = LedgerEntry.new(params[:ledger_entry])
# 
#     respond_to do |format|
#       if @ledger_entry.save
#         format.html { redirect_to @ledger_entry, notice: 'LedgerEntry was successfully created.' }
#         format.json { render json: @ledger_entry, status: :created, location: @ledger_entry }
#       else
#         format.html { render action: "new" }
#         format.json { render json: @ledger_entry.errors, status: :unprocessable_entity }
#       end
#     end
#   end

  # PUT /ledger_entries/1
  # PUT /ledger_entries/1.json
#   def update
#     @ledger_entry = LedgerEntry.find(params[:id])
# 
#     respond_to do |format|
#       if @ledger_entry.update_attributes(params[:ledger_entry])
#         format.html { redirect_to @ledger_entry, notice: 'LedgerEntry was successfully updated.' }
#         format.json { head :no_content }
#       else
#         format.html { render action: "edit" }
#         format.json { render json: @ledger_entry.errors, status: :unprocessable_entity }
#       end
#     end
#   end

  # DELETE /ledger_entries/1
  # DELETE /ledger_entries/1.json
#   def destroy
#     @ledger_entry = LedgerEntry.find(params[:id])
#     @ledger_entry.destroy
# 
#     respond_to do |format|
#       format.html { redirect_to ledger_entries_url }
#       format.json { head :no_content }
#     end
#   end

protected

  def assign_invoice
    if params[:invoice_id]
      @invoice = Invoice.find(params[:invoice_id])
      authorize! :show, @invoice
    end
  end
  
end
