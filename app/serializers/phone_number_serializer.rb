class PhoneNumberSerializer < ActiveModel::Serializer
  attributes :id, :type, :workflow_state, :number, :provider_sid
  has_one :team
end
