class ThenClausesController < ProtectedController
  before_action :set_then_clause, only: [:update, :destroy]

  respond_to :html

  def create
    @then_clause = ThenClause.new(then_clause_params)
    authorize @then_clause
    authorize @then_clause.if_clause.parent, :edit?

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
      authorize @then_clause
    end

    def then_clause_params
      params.require(:then_clause).permit(:type, :if_clause_id)
    end
end
