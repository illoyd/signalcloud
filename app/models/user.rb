class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :trackable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :async, :invitable, :registerable

  has_many :authorizations, inverse_of: :user, autosave: true
  has_many :user_roles, inverse_of: :user
  has_many :organizations, through: :user_roles
  has_many :owned_organizations, foreign_key: 'owner_id', class_name: "Organization", inverse_of: :owner

  def self.find_by_email( email )
    where( email: email.chomp.downcase ).first
  end
  
  def self.from_omniauth( auth, current_user=nil )
    authorization = Authorization.for_provider( auth.provider, auth )

    unless authorization.user
      user = current_user || User.where( email: auth.info.email ).first

      unless user
        user = User.new( email: auth.info.email, name: auth.info.name, password: Devise.friendly_token[0,20] )
        auth.provider == "twitter" ? user.save(:validate => false) : user.save
      end

      authorization.username = auth.info.nickname
      authorization.user = user
      authorization.save
    end

    authorization.user
  end
   
  def nickname
    read_attribute(:nickname) || name
  end
  
  def name
    read_attribute(:name) || 'Anonymous'
  end
  
  def owner_of?(org)
    self.owned_organizations.include? org
  end
  
  def roles_for(org)
    org = org.id if org.is_a? Organization
    self.user_roles.where( organization_id: org ).first
  end
  
  def has_pending_invitation?
    !self.invitation_sent_at.nil? and self.invitation_accepted_at.nil?
  end
  
  def set_roles_for( organization, roles )
    rr = roles_for organization
    rr = UserRole.new( user: self, organization: organization ) if rr.nil?
    rr.roles = roles
    rr.save
  end
  
  UserRole::ROLES.each do |role|
    define_method "is_#{role.to_s}_for?" do |org|
      self.roles_for(org).send("is_#{role.to_s}?")
    end
  end

end
