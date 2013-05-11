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
    
    # Loop over the collection of roles to grant special privileges
    User::ROLES.each do |role|
      if user.send("is_#{role.to_s}?")
        send("grant_#{role.to_s}_privileges", user)
      end
    end
    
    # Specifically do not allow deleting self
    cannot :destroy, user

#     case user.role
#       # 'Normal' users - general access, but no organization management
#       when User::ROLE_USER
#         # Can read, create, and update standard objects
#         can [ :read, :create, :update ], [ Stencil, PhoneNumber, PhoneBook ], { organization_id: user.organization_id }
#         can [ :read, :create, :update ], [ Conversation ], { stencil: { organization_id: user.organization_id } }
#         can [ :show ], Organization
#         
#         # Can view and update own profile
#         can [ :show, :update ], User, { id: user.id }
#         
#         # Explicitly block major items
#         cannot :manage, [ AccountPlan ]
#         cannot [ :index, :create, :update, :delete ], Organization
#       
#       # 'Owner' users - own and manage the organization
#       when User::ROLE_OWNER
#         # Can manage standard objects
#         can :manage, [ Stencil, PhoneNumber, PhoneBook ], { organization_id: user.organization_id }
#         can [ :read, :create, :update ], [ Conversation ], { stencil: { organization_id: user.organization_id } }
#         
#         # Can see ledger_entries
#         can :read, LedgerEntry, { organization_id: user.organization_id }
# 
#         # Can manage own organization users
#         can :manage, User, { organization_id: user.organization_id }
#         
#         # Explicitly block major items
#         cannot :manage, [ AccountPlan ]
#         cannot [ :index, :create, :update, :destroy ], Organization
#       
#       # 'Admin' users - super organizations with multiple organizations
#       when User::ROLE_ADMIN
#         can :manage, :all
#       
#       # Everyone else... can only sign in
#       else
#         can :manage, Session
#       end
  end
  
  # Roles, from User, for ease of reference
  # [ :super_user, :organization_administrator, :developer, :billing_liaison, :conversation_manager ]
  
  def grant_super_user_privileges(user)
    grant_shadow_organization_privileges user
    can :manage, AccountPlan
  end
  
  def grant_organization_administrator_privileges(user)
    grant_manage_users_privileges user
    grant_manage_user_permissions_privileges user
  end
  
  def grant_developer_privileges(user)
    grant_manage_stencils_privileges user
    grant_manage_phone_numbers_privileges user
    grant_manage_phone_books_privileges user
  end
  
  def grant_billing_liaison_privileges(user)
    grant_manage_organization_privileges user
    grant_manage_ledger_entries_privileges user
  end
  
  def grant_conversation_manager_privileges(user)
    grant_force_conversation_privileges user
    grant_start_conversation_privileges user
  end
  
  def grant_default_privileges(user)
    # Show for owning organization
    can :show, [ Organization ], { id: user.organization_id }
    
    # Index and show for primary objects
    can :read, [ Stencil, PhoneNumber, PhoneBook, PhoneBookEntry ], { organization_id: user.organization_id }
    can :read, [ Conversation ], { stencil: { organization_id: user.organization_id } }
    can :read, [ Message ], { conversation: { stencil: { organization_id: user.organization_id } } }
    
    # Show, edit, and update self
    can [ :show, :edit, :update, :change_password ], User, { id: user.id }
  end
  
  def grant_shadow_organization_privileges(user)
    # Edit, update for owning organization
    can [:index, :shadow], Organization
  end
  
  def grant_manage_organization_privileges(user)
    # Edit, update for owning organization
    can [:edit, :update], Organization, { id: user.organization_id }
  end
  
  def grant_manage_users_privileges(user)
    # All for organization users
    can [:create, :read, :update, :destroy], User, { organization_id: user.organization_id }
  end
  
  def grant_manage_user_permissions_privileges(user)
    # All for organization users
    can :permissions, User, { organization_id: user.organization_id }
  end
  
  def grant_manage_stencils_privileges(user)
    # All for organization stencils
    can :manage, Stencil, { organization_id: user.organization_id }
  end
  
  def grant_manage_phone_numbers_privileges(user)
    # All for organization phone numbers
    can :manage, PhoneNumber, { organization_id: user.organization_id }
  end
  
  def grant_manage_phone_books_privileges(user)
    # All for organization phone books
    can :manage, PhoneBook, { organization_id: user.organization_id }
    can [:create, :destroy], PhoneBookEntry, { phone_book: { organization_id: user.organization_id } }
  end
  
  def grant_manage_ledger_entries_privileges(user)
    # Read (no editing!) for ledger entries
    can :read, LedgerEntry, { organization_id: user.organization_id }
  end
  
  def grant_force_conversation_privileges(user)
    # Allow forcing conversations
    can [:force], Conversation, { stencil: { organization_id: user.organization_id } }
  end
  
  def grant_start_conversation_privileges(user)
    # Allow new, create for conversations
    can [:new, :create], Conversation, { stencil: { organization_id: user.organization_id } }
  end
  
end
