class MockedCommunicationGateway
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include Workflow
  
  workflow do
    state :new do
      event :create_remote, transitions_to: :ready
    end
    state :ready do
      event :update_remote, transitions_to: :ready
    end
  end
  
  attr_accessor :id, :organization_id, :remote_side, :remote_token, :remote_application, :updated_remote_at, :created_at, :updated_at
  # has_many :phone_numbers, inverse_of: :communication_gateway
  
  validates_presence_of :type #, :organization, :type
  validates_presence_of :remote_sid, :remote_token, if: :ready?
  
  def type
    @type ||= self.class.name
  end

end
