class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :trackable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :async, :invitable
  devise :registerable if ALLOW_USER_REGISTRATION

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :first_name, :last_name
  
  has_many :user_roles, inverse_of: :user
  has_many :organizations, through: :user_roles
  
  validates_presence_of :first_name, :last_name
  
#   def method_missing(sym, *args, &block)
#     if /^can_(.+)\?$/.match(sym) and UserRole::ROLES.include?($1.to_sym)
#       return self.roles.include? $1.to_sym
#     else
#       super( sym, *args, &block )
#     end
#   end
#   
#   def respond_to?(sym, include_private=false)
#     return (/^can_(.+)\?$/.match(sym) and UserRole::ROLES.include?($1.to_sym)) || super( sym, include_private )
#   end

  def roles_for(org)
    org = org.id if org.is_a? Organization
    self.user_roles.where( organization_id: org ).first
  end

end
