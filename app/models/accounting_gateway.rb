class AccountingGateway < ActiveRecord::Base
  include Workflow
  
  attr_encrypted :remote_sid, key: ATTR_ENCRYPTED_SECRET

  belongs_to :organization, inverse_of: :accounting_gateway

  attr_accessible :remote_sid

  validates_presence_of :remote_sid, if: :ready?

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