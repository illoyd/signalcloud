class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :account, :first_name, :last_name, :role
  
  belongs_to :account, inverse_of: :users

  ROLE_USER = 'user'
  ROLE_OWNER = 'owner'
  ROLE_ADMIN = 'admin'
  
  validates_inclusion_of :role, in: [ ROLE_USER, ROLE_OWNER, ROLE_ADMIN ]
end
