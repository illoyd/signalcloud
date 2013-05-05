class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :trackable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :async, :invitable
  devise :registerable if ALLOW_USER_REGISTRATION

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :account, :account_id, :first_name, :last_name, :roles
  
  belongs_to :account, inverse_of: :users
  
  validates_presence_of :first_name, :last_name, :roles_mask, :account_id

  ROLES = [ :super_user, :account_administrator, :developer, :billing_liaison, :conversation_manager ]
  
  before_validation :ensure_account_when_invited

#   def method_missing(sym, *args, &block)
#     if /^can_(.+)\?$/.match(sym) and User::ROLES.include?($1.to_sym)
#       return self.roles.include? $1.to_sym
#     else
#       super( sym, *args, &block )
#     end
#   end
#   
#   def respond_to?(sym, include_private=false)
#     return (/^can_(.+)\?$/.match(sym) and User::ROLES.include?($1.to_sym)) || super( sym, include_private )
#   end

  def ensure_account_when_invited
    if self.account_id.blank? and !self.invited_by.nil?
      self.account_id = self.invited_by.account_id
    end
  end
  
  def roles=(new_roles)
    #new_roles.map! { |entry| entry.to_sym }
    #self.roles_mask = (new_roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
    self.roles_mask = User.translate_roles( new_roles )
  end
  
  def roles
    ROLES.reject do |r|
      ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end
  
  def self.translate_roles( new_roles=[] )
    new_roles = [] if new_roles.nil?
    new_roles.map! { |entry| entry.to_sym }
    return (new_roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
  end
  
  ROLES.each do |role|
    define_method 'is_' + role.to_s + '?' do
      self.roles.include? role
    end
  end

end
