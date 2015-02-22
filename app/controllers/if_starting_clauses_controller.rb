class IfStartingClausesController < IfClausesController
  private
    def set_if_clause
      @if_clause = IfStartingClause.create_with(if_clause_params).find_or_initialize_by(id: params[:id])
    end

    def if_clause_params
      params.require(:if_starting_clause).permit(:type, :parent_id, :parent_type)
    end
end
