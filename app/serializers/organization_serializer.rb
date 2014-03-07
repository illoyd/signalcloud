class OrganizationSerializer < ActiveModel::Serializer
  # include ConversationsHelper

  attributes :id, :label, :created_at, :updated_at
  
end
