class TeamSerializer < ActiveModel::Serializer
  attributes :id, :workflow_state, :name, :description
  has_one :user
end
