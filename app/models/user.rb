class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :trackable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :async
  devise :registerable if ALLOW_USER_REGISTRATION

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :account, :account_id, :first_name, :last_name, :roles
  
  belongs_to :account, inverse_of: :users
  
  validates_presence_of :first_name, :last_name, :roles_mask, :account_id

  ROLES = [ :shadow_account, :manage_account, :manage_users, :manage_user_permissions, :manage_stencils, :manage_phone_numbers, :manage_phone_books, :start_conversation, :force_conversation, :manage_ledger_entries ]

  def method_missing(sym, *args, &block)
    if /^can_(.+)\?$/.match(sym) and User::ROLES.include?($1.to_sym)
      return self.roles.include? $1.to_sym
    else
      super( sym, *args, &block )
    end
  end
  
  def respond_to?(sym, include_private=false)
    return (/^can_(.+)\?$/.match(sym) and User::ROLES.include?($1.to_sym)) || super( sym, include_private )
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

end
