class IfStartingClausesController < IfClausesController
  private
    def if_clause_params
      params.require(:if_starting_clause).permit(:type, :parent_id)
    end
end
