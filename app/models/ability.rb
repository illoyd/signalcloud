class Ability
  include CanCan::Ability
  
  STANDARD_OBJECTS = [ Appliance, PhoneNumber, PhoneDirectory, Ticket ]

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
      if user.send("can_#{role.to_s}?")
        send("grant_#{role.to_s}_privileges", user)
      end
    end

#     case user.role
#       # 'Normal' users - general access, but no account management
#       when User::ROLE_USER
#         # Can read, create, and update standard objects
#         can [ :read, :create, :update ], [ Appliance, PhoneNumber, PhoneDirectory ], { account_id: user.account_id }
#         can [ :read, :create, :update ], [ Ticket ], { appliance: { account_id: user.account_id } }
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
#         can :manage, [ Appliance, PhoneNumber, PhoneDirectory ], { account_id: user.account_id }
#         can [ :read, :create, :update ], [ Ticket ], { appliance: { account_id: user.account_id } }
#         
#         # Can see transactions
#         can :read, Transaction, { account_id: user.account_id }
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
  
  # [ :shadow_account, :manage_account, :manage_users, :manage_appliances, :manage_phone_numbers, :manage_phone_directories, :manage_tickets, :start_ticket ]
  
  def grant_default_privileges(user)
    # Index and show for primary objects
    can :read, [ Appliance, PhoneNumber, PhoneDirectory, Ticket ], { account_id: user.account_id }
    
    # Show for owning account
    can :show, [ Account ], { id: user.account_id }
    
    # Show, edit, and update self
    can [ :show, :edit, :update ], User, { id: user.id }
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
    can :manage, User, { account_id: user.account_id }
  end
  
  def grant_manage_appliances_privileges(user)
    # All for account appliances
    can :manage, Appliance, { account_id: user.account_id }
  end
  
  def grant_manage_phone_numbers_privileges(user)
    # All for account phone numbers
    can :manage, PhoneNumber, { account_id: user.account_id }
  end
  
  def grant_manage_phone_directories_privileges(user)
    # All for account phone directories
    can :manage, PhoneDirectory, { account_id: user.account_id }
    can [:create, :destroy], PhoneDirectoryEntry, { phone_directory: { account_id: user.account_id } }
  end
  
  def grant_force_tickets_privileges(user)
    # Allow forcing tickets
    can [:force], Ticket, { account_id: user.account_id }
  end
  
  def grant_start_ticket_privileges(user)
    # Allow new, create for tickets
    can [:new, :create], Ticket, { account_id: user.account_id }
  end
  
end
