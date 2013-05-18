class UserRole < ActiveRecord::Base

  ROLES = [ :organization_administrator, :developer, :billing_liaison, :conversation_manager ]
  
  attr_accessible :roles, :user, :organization

  belongs_to :user, inverse_of: :user_roles
  belongs_to :organization, inverse_of: :user_roles
  
  validates_presence_of :roles_mask, :user, :organization

  def roles=(new_roles)
    #new_roles.map! { |entry| entry.to_sym }
    #self.roles_mask = (new_roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
    self.roles_mask = self.class.translate_roles( new_roles )
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
