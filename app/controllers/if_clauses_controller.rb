class IfClausesController < ProtectedController
  before_action :set_if_clause, only: [:update, :destroy]

  respond_to :html

  def create
    @if_clause = IfClause.new(if_clause_params)
    authorize @if_clause
    authorize @if_clause.parent, :edit?

    flash[:success] = "#{ @if_clause } was added to #{ @if_clause.parent.name }." if @if_clause.save
    redirect_to :back
  end

  def update
    @if_clause.assign_attributes(if_clause_params)
    authorize @if_clause.parent, :edit?

    flash[:success] = "#{ @if_clause } was updated in #{ @if_clause.parent.name }." if @if_clause.save
    redirect_to :back
  end
  
  def destroy
    flash[:success] = "#{ @if_clause } was removed from #{ @if_clause.parent.name }." if @if_clause.destroy
    redirect_to :back
  end

  private
    def set_if_clause
      @if_clause = IfClause.find(params[:id])
      authorize @if_clause
    end

    def if_clause_params
      params.require(:if_clause).permit(:type, :parent_id)
    end
end
