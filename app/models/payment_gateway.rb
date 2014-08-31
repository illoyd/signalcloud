class PaymentGateway < ActiveRecord::Base
  include Workflow
  
  attr_encrypted_options.merge!(key: Rails.application.secrets.encrypted_secret, mode: :per_attribute_iv_and_salt)
  attr_encrypted :remote_sid

  belongs_to :organization, inverse_of: :payment_gateway

  validates_presence_of :remote_sid, if: :ready?

  workflow do
    state :new do
      event :create_remote, transitions_to: :ready
    end
    state :ready do
      event :update_remote, transitions_to: :ready
      event :remote_instance, transitions_to: :ready
    end
    state :suspend
  end

end
