class CommunicationGateway < ActiveRecord::Base
  include Workflow
  
  attr_encrypted :remote_sid, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :remote_token, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :organization, inverse_of: :communication_gateway
  
  validates_presence_of :organization
  validates_presence_of :remote_sid, :remote_token, if: :ready?

  attr_accessible :organization, :remote_sid, :remote_token, :remote_application, :workflow_state

  workflow do
    state :new do
      event :create_remote, transitions_to: :ready
    end
    state :ready do
      event :update_remote, transitions_to: :ready
    end
  end
  
private

  def persist_workflow_state(new_value)
    write_attribute self.class.workflow_column, new_value
    save
  end
  
end
