class Box < ActiveRecord::Base
  
  belongs_to :organization, inverse_of: :boxes
  has_many :conversations, inverse_of: :box, dependent: :destroy

  validates_presence_of :organization
  
end
