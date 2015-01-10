class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :lockable, :validatable
  
  has_many :memberships, inverse_of: :user
  has_many :teams, through: :memberships
  has_many :owned_teams, inverse_of: :owner, as: :owner
end
