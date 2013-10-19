class Box < ActiveRecord::Base
  include Workflow
  workflow do
    state :draft do
      event :start, transitions_to: :working
    end
    state :working do
      event :complete, transitions_to: :complete
    end
    state :complete
  end
  
  belongs_to :organization, inverse_of: :boxes
  has_many :conversations, inverse_of: :box, dependent: :destroy
  
  has_attached_file :document

  validates_presence_of :organization
  validates :document, attachment_presence: true, attachment_content_type: [ 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ], if: :draft?
  
  protected
  
  def start
  end
  
  def complete
  end
  
end
