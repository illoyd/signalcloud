Ticketplease::Application.routes.draw do

  # Configure authentication for USERS
  devise_for :users

  # Global resources
  resources :account_plans
  
  # All resources should be accessible outside the account scope as well
  
  # Prevent accounts from being deleted
  resource :account, only: [ :show, :new, :create, :update, :edit ]

  resources :users

  resources :appliances do
    collection do
      get 'active', action: :index, defaults: { active_filter: true }, as: 'active'
      get 'inactive', action: :index, defaults: { active_filter: false }, as: 'inactive'
    end
    resources :tickets, only: [ :index, :new, :create ] do
      member do
        post 'force', action: 'force_status', as: 'force_status'
      end
      collection do
        get 'page/:page', action: :index
        get 'confirmed', action: :index, defaults: { status: Ticket::CONFIRMED } do
          get 'page/:page', action: :index
        end
        get 'denied', action: :index, defaults: { status: Ticket::DENIED } do
          get 'page/:page', action: :index, on: :collection
        end
        get 'failed', action: :index, defaults: { status: Ticket::FAILED } do
          get 'page/:page', action: :index, on: :collection
        end
        get 'expired', action: :index, defaults: { status: Ticket::EXPIRED } do
          get 'page/:page', action: :index, on: :collection
        end
        get 'open', action: :index, defaults: { status: [Ticket::QUEUED, Ticket::CHALLENGE_SENT] } do
          get 'page/:page', action: :index, on: :collection
        end
      end
    end
  end

  resources :tickets, only: [ :index, :show ] do
    collection do
      get 'page/:page', action: :index
      get 'confirmed', action: :index, defaults: { status: Ticket::CONFIRMED } do
        get 'page/:page', action: :index, on: :collection
      end
      get 'denied', action: :index, defaults: { status: Ticket::DENIED } do
        get 'page/:page', action: :index, on: :collection
      end
      get 'failed', action: :index, defaults: { status: Ticket::FAILED } do
        get 'page/:page', action: :index, on: :collection
      end
      get 'expired', action: :index, defaults: { status: Ticket::EXPIRED } do
        get 'page/:page', action: :index, on: :collection
      end
      get 'open', action: :index, defaults: { status: [Ticket::QUEUED, Ticket::CHALLENGE_SENT] } do
        get 'page/:page', action: :index, on: :collection
      end
    end
  end

  resources :ledger_entries, only: [ :index, :show ]

  resources :phone_numbers, only: [ :index, :show ] do
    collection do
      get 'search/:country', action: 'search', defaults: { country: 'US' }, constraint: { country: /(US|CA|GB)/ }, as: 'search'
      post 'buy', action: 'buy', as: 'buy'
    end
  end

  resources :phone_directories
  resources :phone_directory_entries, only: [:create, :destroy]
  
  # Nested resources via account
  # This functionality has been removed in favour of shadowing the current account using the session.
  #resources :accounts do
  #  resources :users
  #  resources :appliances
  #  resources :tickets, only: [ :index, :new, :create, :show ]
  #  resources :messages, only: [ :show ]
  #  resources :ledger_entries, only: [ :index, :show ]
  #  resources :phone_numbers, only: [ :index, :create ]
  #  resources :phone_directories
  #end
  
  # Twilio API extension
  namespace :twilio do
    resource :inbound_call, only: [ :create ], :defaults => { :format => 'xml' }
    resource :inbound_sms, only: [ :create ], :defaults => { :format => 'xml' }
    resource :sms_callback, only: [:create], defaults: { format: 'xml' }
  end

  resources :accounts, only: [:index] do
    member do
      get 'shadow', action: 'shadow' #, as: 'shadow'
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'accounts#show'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
