class PhoneBookSerializer < ActiveModel::Serializer
  attributes :id, :workflow_state, :name, :description
  has_one :team
end
