class ThenSetStatusClausesController < ThenClausesController
  private
    def set_then_clause
      @then_clause = ThenSetStatusClause.create_with(then_clause_params).find_or_initialize_by(id: params[:id])
    end

    def then_clause_params
      params.require(:then_set_status_clause).permit(:if_clause_id, :status)
    end
end
