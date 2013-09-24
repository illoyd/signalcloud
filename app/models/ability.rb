class Ability
  include CanCan::Ability
  
  STANDARD_OBJECTS = [ Stencil, PhoneNumber, PhoneBook, Conversation ]

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    
    # Grant all default privileges
    grant_default_privileges(user)
    
    # Iterate over every assigned role(s) to each organization
    user.user_roles.each do |user_role|
      UserRole::ROLES.each do |role|
        if user_role.send("is_#{role.to_s}?")
          send("grant_#{role.to_s}_privileges", user, user_role.organization_id)
        end
      end
    end
    
    # Find all owned organizations and grant everything!
    user.owned_organizations.pluck(:id).each do |organization_id|
     UserRole::ROLES.each do |role|
       send("grant_#{role.to_s}_privileges", user, organization_id)
     end
    end
    
    # Grant system admin
    grant_system_admin_privileges(user) if user.system_admin
    
    # Specifically do not allow deleting self
    can :read, user
    can :read, UserRole, { user_id: user.id }
    cannot [:edit, :destroy], UserRole, { user_id: user.id }
    cannot :destroy, user

  end
  
  # Roles, from User, for ease of reference
  # [ :organization_administrator, :developer, :billing_liaison, :conversation_manager ]
  
  def grant_system_admin_privileges(user)
    can :manage, AccountPlan
  end
  
  def grant_organization_administrator_privileges(user, organization_id)
    grant_manage_users_privileges user, organization_id
    grant_manage_user_permissions_privileges user, organization_id
  end
  
  def grant_developer_privileges(user, organization_id)
    grant_manage_stencils_privileges user, organization_id
    grant_manage_phone_numbers_privileges user, organization_id
    grant_manage_phone_books_privileges user, organization_id
  end
  
  def grant_billing_liaison_privileges(user, organization_id)
    grant_manage_organization_privileges user, organization_id
    grant_manage_ledger_entries_privileges user, organization_id
  end
  
  def grant_conversation_manager_privileges(user, organization_id)
    grant_force_conversation_privileges user, organization_id
    grant_start_conversation_privileges user, organization_id
  end
  
  def grant_default_privileges(user)
    # Show for owning organization
    can [ :index, :show, :shadow ], [ Organization ], { id: user.organization_ids }
    
    # Index and show for primary objects
    can :read, [ Stencil, PhoneNumber, PhoneBook, PhoneBookEntry ], { organization_id: user.organization_ids }
    can :read, [ Conversation ], { stencil: { organization_id: user.organization_ids } }
    can :read, [ Message ], { conversation: { stencil: { organization_id: user.organization_ids } } }

    # Create organizations if allowed    
    # can( [:new, :create], Organization, { id: user.organization_ids } ) if ALLOW_ORG_CREATION
    can( [:new, :create], Organization, { user_roles: { user_id: user.id } } ) if ALLOW_ORG_CREATION

    # Show, edit, and update self
    can [ :show, :edit, :update, :change_password ], User, { id: user.id }
  end
  
  def grant_manage_organization_privileges(user, organization_id)
    # Edit, update for owning organization
    can [:edit, :update], Organization, { id: organization_id }
  end
  
  def grant_manage_users_privileges(user, organization_id)
    # All for organization users
    can [:index, :show], User, organizations: { id: organization_id }
  end
  
  def grant_manage_user_permissions_privileges(user, organization_id)
    # All for organization users
    can :manage, UserRole, organization_id: organization_id
  end
  
  def grant_manage_stencils_privileges(user, organization_id)
    # All for organization stencils
    can :manage, Stencil, { organization_id: organization_id }
  end
  
  def grant_manage_phone_numbers_privileges(user, organization_id)
    # All for organization phone numbers
    can :manage, PhoneNumber, { organization_id: organization_id }
  end
  
  def grant_manage_phone_books_privileges(user, organization_id)
    # All for organization phone books
    can :manage, PhoneBook, { organization_id: organization_id }
    can [:create, :destroy], PhoneBookEntry, { phone_book: { organization_id: organization_id } }
  end
  
  def grant_manage_ledger_entries_privileges(user, organization_id)
    # Read (no editing!) for ledger entries
    can :read, LedgerEntry, { organization_id: organization_id }
    can :read, Invoice,     { organization_id: organization_id }
  end
  
  def grant_force_conversation_privileges(user, organization_id)
    # Allow forcing conversations
    can [:force], Conversation, { stencil: { organization_id: organization_id } }
  end
  
  def grant_start_conversation_privileges(user, organization_id)
    # Allow new, create for conversations
    can [:new, :create], Conversation, { stencil: { organization_id: organization_id } }
  end
  
end
