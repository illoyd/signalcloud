class ConversationSerializer < ActiveModel::Serializer
  include ConversationsHelper

  attributes :id, :stencil_id, :stencil_label, :status, :challenge_status, :reply_status, :status_text, :challenge_status_text, :reply_status_text, :expires_at, :webhook_uri, :to_number, :from_number, :question, :confirmed_reply, :denied_reply, :expired_reply, :failed_reply, :challenge_sent_at, :response_received_at, :reply_sent_at
  
  def challenge_status_text
    human_status_for( object.challenge_status )
  end

  def reply_status_text
    human_status_for( object.reply_status )
  end
  
  def status_text
    human_status_for( object.status )
  end
  
  def stencil_label
    object.stencil.label
  end

end
