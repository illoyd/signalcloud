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

  validates_presence_of :organization
  
  protected
  
  def start
  end
  
  def complete
  end
  
end
