class Team < ActiveRecord::Base
  belongs_to :owner, inverse_of: :owned_teams, class_name: User
  has_many :memberships, inverse_of: :team
  has_many :users, through: :memberships
  
  validates :name, presence: true
  validates :owner, presence: true
end
