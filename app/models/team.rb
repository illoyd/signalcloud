class Team < ActiveRecord::Base
  belongs_to :owner, inverse_of: :owned_teams, class_name: User
  has_many :memberships, inverse_of: :team
  has_many :users, through: :memberships

#   has_many :conversations, inverse_of: :team
#   has_many :invoices,      inverse_of: :team
#   has_many :journals,      inverse_of: :team
  has_many :phone_numbers, inverse_of: :team
#   has_many :stencils,      inverse_of: :team
  
  validates :name, presence: true
  validates :owner, presence: true
  
  normalize_attributes :name, :description
  
  include Workflow
  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
  end
end
