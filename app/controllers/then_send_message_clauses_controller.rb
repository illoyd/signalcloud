class ThenSendMessageClausesController < ThenClausesController
  private
    def set_then_clause
      @then_clause = ThenSendMessageClause.create_with(then_clause_params).find_or_initialize_by(id: params[:id])
    end

    def then_clause_params
      params.require(:then_send_message_clause).permit(:if_clause_id, :message)
    end
end
