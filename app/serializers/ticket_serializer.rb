class TicketSerializer < ActiveModel::Serializer
  attributes :id, :stencil_id, :status, :challenge_status, :reply_status, :status_text, :challenge_status_text, :reply_status_text, :expires_at, :webhook_uri, :to_number, :from_number, :question, :confirmed_reply, :denied_reply, :expired_reply, :failed_reply, :challenge_sent_at, :response_received_at, :reply_sent_at
  
  def challenge_status_text
    Ticket.status_text( self.challenge_status )
  end

  def reply_status_text
    Ticket.status_text( self.reply_status )
  end

end
