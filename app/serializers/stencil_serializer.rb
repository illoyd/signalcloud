class StencilSerializer < ActiveModel::Serializer
  attributes :id, :workflow_state, :name, :description
  has_one :team
  has_one :phone_book
end
