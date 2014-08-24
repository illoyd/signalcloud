class AccountPlansController < ProtectedController

  load_and_authorize_resource


  # GET /account_plans
  # GET /account_plans.json
  def index
    @account_plans = AccountPlan.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @account_plans }
    end
  end

  # GET /account_plans/1
  # GET /account_plans/1.json
  def show
    @account_plan = AccountPlan.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account_plan }
    end
  end

  # GET /account_plans/new
  # GET /account_plans/new.json
  def new
    @account_plan = AccountPlan.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account_plan }
    end
  end

  # GET /account_plans/1/edit
  def edit
    @account_plan = AccountPlan.find(params[:id])
  end

  # POST /account_plans
  # POST /account_plans.json
  def create
    @account_plan = AccountPlan.new(params[:account_plan])

    respond_to do |format|
      if @account_plan.save
        format.html { redirect_to @account_plan, notice: 'Organization plan was successfully created.' }
        format.json { render json: @account_plan, status: :created, location: @account_plan }
      else
        format.html { render action: "new" }
        format.json { render json: @account_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /account_plans/1
  # PUT /account_plans/1.json
  def update
    @account_plan = AccountPlan.find(params[:id])

    respond_to do |format|
      if @account_plan.update_attributes(params[:account_plan])
        format.html { redirect_to @account_plan, notice: 'Organization plan was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_plans/1
  # DELETE /account_plans/1.json
  def destroy
    @account_plan = AccountPlan.find(params[:id])
    @account_plan.destroy

    respond_to do |format|
      format.html { redirect_to account_plans_url }
      format.json { head :no_content }
    end
  end
end
