class AccountsController < ApplicationController

  respond_to :html, :json, :xml
  before_filter :assign_current_account, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  def assign_current_account
    @account = current_account
  end

  # GET /accounts
  # GET /accounts.json
  def index
    @accounts = Account.all( order: :label )
    respond_with @accounts
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
    #@account = current_account # Account.find( params.fetch( :account_id, params[:id] ) )
    respond_with @account
  end

  # GET /accounts/new
  # GET /accounts/new.json
  def new
    @account = Account.new
    #respond_with @account
#     respond_to do |format|
#       format.html # new.html.erb
#       format.json { render json: @account }
#     end
  end

  # GET /accounts/1/edit
  def edit
    #@account = current_account
    respond_with @account
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new( params[:account] )
    if @account.save
      flash[:success] = 'Your account has been created.'
    end
    respond_with @account
  end

  # PUT /accounts/1
  # PUT /accounts/1.json
  def update
    #@account = current_account
    if @account.update_attributes(params[:account])
      flash[:success] = 'Your account has been updated.'
    end
    respond_with @account
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    #@account = current_account
    @account.destroy
    flash[:alert] = "Successfully destroyed account."
    respond_with(@account)
  end
  
  def shadow
    # Only set the shadow option if allows
    if current_user.can_shadow_account?
      session[:shadow_account_id] = params[:account_id]
    end
    redirect_to account_path
  end
end
