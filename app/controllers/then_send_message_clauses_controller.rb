class ThenSendMessageClausesController < ThenClausesController
  private
    def then_clause_params
      params.require(:then_send_message_clause).permit(:if_clause_id, :message)
    end
end
