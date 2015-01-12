class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :lockable, :validatable
  
  has_many :memberships, inverse_of: :user
  has_many :teams, through: :memberships
  has_many :owned_teams, inverse_of: :owner, as: :owner
  
  normalize_attributes :name, :nickname
  
  def team_ids
    memberships.pluck(:team_id)
  end
  
  def membership_for(team_or_id)
    memberships.find_by(team_id: team_or_id.try(:id) || team_or_id) || Membership.new(user: self)
  end
end
