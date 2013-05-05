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
#       # 'Normal' users - general access, but no account management
#       when User::ROLE_USER
#         # Can read, create, and update standard objects
#         can [ :read, :create, :update ], [ Stencil, PhoneNumber, PhoneBook ], { account_id: user.account_id }
#         can [ :read, :create, :update ], [ Conversation ], { stencil: { account_id: user.account_id } }
#         can [ :show ], Account
#         
#         # Can view and update own profile
#         can [ :show, :update ], User, { id: user.id }
#         
#         # Explicitly block major items
#         cannot :manage, [ AccountPlan ]
#         cannot [ :index, :create, :update, :delete ], Account
#       
#       # 'Owner' users - own and manage the account
#       when User::ROLE_OWNER
#         # Can manage standard objects
#         can :manage, [ Stencil, PhoneNumber, PhoneBook ], { account_id: user.account_id }
#         can [ :read, :create, :update ], [ Conversation ], { stencil: { account_id: user.account_id } }
#         
#         # Can see ledger_entries
#         can :read, LedgerEntry, { account_id: user.account_id }
# 
#         # Can manage own account users
#         can :manage, User, { account_id: user.account_id }
#         
#         # Explicitly block major items
#         cannot :manage, [ AccountPlan ]
#         cannot [ :index, :create, :update, :destroy ], Account
#       
#       # 'Admin' users - super accounts with multiple accounts
#       when User::ROLE_ADMIN
#         can :manage, :all
#       
#       # Everyone else... can only sign in
#       else
#         can :manage, Session
#       end
  end
  
  # Roles, from User, for ease of reference
  # [ :super_user, :account_administrator, :developer, :billing_liaison, :conversation_manager ]
  
  def grant_super_user_privileges(user)
    grant_shadow_account_privileges user
    can :manage, AccountPlan
  end
  
  def grant_account_administrator_privileges(user)
    grant_manage_users_privileges user
    grant_manage_user_permissions_privileges user
  end
  
  def grant_developer_privileges(user)
    grant_manage_stencils_privileges user
    grant_manage_phone_numbers_privileges user
    grant_manage_phone_books_privileges user
  end
  
  def grant_billing_liaison_privileges(user)
    grant_manage_account_privileges user
    grant_manage_ledger_entries_privileges user
  end
  
  def grant_conversation_manager_privileges(user)
    grant_force_conversation_privileges user
    grant_start_conversation_privileges user
  end
  
  def grant_default_privileges(user)
    # Show for owning account
    can :show, [ Account ], { id: user.account_id }
    
    # Index and show for primary objects
    can :read, [ Stencil, PhoneNumber, PhoneBook, PhoneBookEntry ], { account_id: user.account_id }
    can :read, [ Conversation ], { stencil: { account_id: user.account_id } }
    can :read, [ Message ], { conversation: { stencil: { account_id: user.account_id } } }
    
    # Show, edit, and update self
    can [ :show, :edit, :update, :change_password ], User, { id: user.id }
  end
  
  def grant_shadow_account_privileges(user)
    # Edit, update for owning account
    can [:index, :shadow], Account
  end
  
  def grant_manage_account_privileges(user)
    # Edit, update for owning account
    can [:edit, :update], Account, { id: user.account_id }
  end
  
  def grant_manage_users_privileges(user)
    # All for account users
    can [:create, :read, :update, :destroy], User, { account_id: user.account_id }
  end
  
  def grant_manage_user_permissions_privileges(user)
    # All for account users
    can :permissions, User, { account_id: user.account_id }
  end
  
  def grant_manage_stencils_privileges(user)
    # All for account stencils
    can :manage, Stencil, { account_id: user.account_id }
  end
  
  def grant_manage_phone_numbers_privileges(user)
    # All for account phone numbers
    can :manage, PhoneNumber, { account_id: user.account_id }
  end
  
  def grant_manage_phone_books_privileges(user)
    # All for account phone books
    can :manage, PhoneBook, { account_id: user.account_id }
    can [:create, :destroy], PhoneBookEntry, { phone_book: { account_id: user.account_id } }
  end
  
  def grant_manage_ledger_entries_privileges(user)
    # Read (no editing!) for ledger entries
    can :read, LedgerEntry, { account_id: user.account_id }
  end
  
  def grant_force_conversation_privileges(user)
    # Allow forcing conversations
    can [:force], Conversation, { stencil: { account_id: user.account_id } }
  end
  
  def grant_start_conversation_privileges(user)
    # Allow new, create for conversations
    can [:new, :create], Conversation, { stencil: { account_id: user.account_id } }
  end
  
end
