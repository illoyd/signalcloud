class ThenClausesController < ProtectedController
  before_action :set_then_clause, only: [:create, :update, :destroy]
  before_action :authorize_then_clause, only: [:create, :update, :destroy]

  respond_to :html

  def create
    flash[:success] = "#{ @then_clause } was added to #{ @then_clause.if_clause.parent.name }." if @then_clause.save
    redirect_to :back
  end

  def update
    @then_clause.assign_attributes(then_clause_params)
    authorize @then_clause.if_clause.parent, :edit?

    flash[:success] = "#{ @then_clause } was updated in #{ @then_clause.if_clause.parent.name }." if @then_clause.save
    redirect_to :back
  end
  
  def destroy
    flash[:success] = "#{ @then_clause } was removed from #{ @then_clause.if_clause.parent.name }." if @then_clause.destroy
    redirect_to :back
  end

  private
    def set_then_clause
      @then_clause = ThenClause.find(params[:id])
    end

    def authorize_then_clause
      authorize @then_clause
      authorize @then_clause.if_clause.parent, :edit?
    end

    def then_clause_params
      params.require(:then_clause).permit(:type, :if_clause_id)
    end
end