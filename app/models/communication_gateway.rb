class CommunicationGateway < ActiveRecord::Base
  include Workflow
  
  workflow do
    state :new do
      event :create_remote, transitions_to: :ready
    end
    state :ready do
      event :update_remote, transitions_to: :ready
    end
  end

  attr_encrypted :remote_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :remote_token, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :organization, inverse_of: :communication_gateways
  has_many :phone_numbers, inverse_of: :communication_gateway
  
  validates_presence_of :organization, :type
  validates_presence_of :remote_sid, :remote_token, if: :ready?

  # Legacy aliases for Twilio
  alias_method :twilio_account_sid,  :remote_sid
  alias_method :twilio_account_sid=, :remote_sid=

  alias_method :twilio_auth_token,  :remote_token
  alias_method :twilio_auth_token=, :remote_token=

  alias_method :twilio_application,  :remote_application
  alias_method :twilio_application=, :remote_application=
  
  alias_method :twilio_application_sid,  :remote_application
  alias_method :twilio_application_sid=, :remote_application=
end
