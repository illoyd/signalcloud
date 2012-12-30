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

    case user.role
      # 'Normal' users - general access, but no account management
      when User::ROLE_USER
        # Can read, create, and update standard objects
        can [ :read, :create, :update ], [ Appliance, PhoneNumber, PhoneDirectory ], { account_id: user.account_id }
        can [ :read, :create, :update ], [ Ticket ], { appliance: { account_id: user.account_id } }
        can [ :show ], Account
        
        # Can view and update own profile
        can [ :show, :update ], User, { id: user.id }
        
        # Explicitly block major items
        cannot :manage, [ AccountPlan ]
        cannot [ :index, :create, :update, :delete ], Account
      
      # 'Owner' users - own and manage the account
      when User::ROLE_OWNER
        # Can manage standard objects
        can :manage, [ Appliance, PhoneNumber, PhoneDirectory ], { account_id: user.account_id }
        can [ :read, :create, :update ], [ Ticket ], { appliance: { account_id: user.account_id } }
        
        # Can see transactions
        can :read, Transaction, { account_id: user.account_id }

        # Can manage own account users
        can :manage, User, { account_id: user.account_id }
        
        # Explicitly block major items
        cannot :manage, [ AccountPlan ]
        cannot [ :index, :create, :update, :destroy ], Account
      
      # 'Admin' users - super accounts with multiple accounts
      when User::ROLE_ADMIN
        can :manage, :all
      
      # Everyone else... can only sign in
      else
        can :manage, Session
      end
  end
end
