class ApplianceSerializer < ActiveModel::Serializer
  attributes :id, :label, :primary, :phone_directory_id, :description, :webhook_uri, :seconds_to_live, :question, :expected_confirmed_answer, :expected_denied_answer, :confirmed_reply, :denied_reply, :failed_reply, :expired_reply, :created_at, :updated_at
end
