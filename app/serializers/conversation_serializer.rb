class ConversationSerializer < ActiveModel::Serializer
  include ConversationsHelper

  attributes :id, :stencil_id, :stencil_label, :challenge_status, :reply_status, :customer_number, :internal_number, :question, :confirmed_reply, :denied_reply, :failed_reply, :expired_reply, :webhook_uri, :expires_at, :challenge_sent_at, :response_received_at, :reply_sent_at, :created_at, :updated_at
  attribute :workflow_state, key: :status
  
  def stencil_label
    object.stencil.label
  end
  
  def customer_number
    "+#{ object.customer_number }"
  end

  def internal_number
    "+#{ object.internal_number.number }"
  end

end
