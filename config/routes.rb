SignalCloud::Application.routes.draw do

  # Configure authentication for USERS
  devise_for :users #, :controllers => { :invitations => 'users/invitations' }

  # Global resources
  resources :account_plans
  
  # All resources should be accessible outside the organization scope as well
  resources :users, only: [ :show, :update, :edit ]
  
  # Nest all underneath organizations
  resources :organizations, only: [ :index, :new, :show, :create, :update, :edit ] do
    resources :users, only: [ :index ]
    resources :user_roles, only: [ :create, :update, :destroy ]
    
    resources :boxes do
      resources :conversations, only: [ :index, :new, :create ] do
        collection do
          get 'page/:page', action: :index
        end
      end
    end

    resources :stencils do
      collection do
        get 'active', action: :index, defaults: { active_filter: true }, as: 'active'
        get 'inactive', action: :index, defaults: { active_filter: false }, as: 'inactive'
      end
      resources :conversations, only: [ :index, :new, :create ] do
        collection do
          get 'page/:page', action: :index
        end
      end
    end
  
    resources :conversations, only: [ :index, :show ] do
      member do
        post 'force', action: 'force_status', as: 'force_status'
      end
      collection do
        get 'page/:page', action: :index
      end
    end

    resources :ledger_entries, only: [ :index, :show ] do
      get 'page/:page', action: :index
    end
    
    get '/invoices/:invoice_id' => 'ledger_entries#index', as: :invoice
  
    resources :phone_numbers, only: [ :index, :show, :create, :edit, :update, :destroy ] do
      collection do
        get 'search/:country/:kind', action: 'search', defaults: { country: 'US', kind: 'local' }, as: 'search'
      end
    end
  
    resources :phone_books
    resources :phone_book_entries, only: [:create, :destroy]

  end

  # Nested resources via organization
  # This functionality has been removed in favour of shadowing the current organization using the session.
  #resources :organizations do
  #  resources :users
  #  resources :stencils
  #  resources :conversations, only: [ :index, :new, :create, :show ]
  #  resources :messages, only: [ :show ]
  #  resources :ledger_entries, only: [ :index, :show ]
  #  resources :phone_numbers, only: [ :index, :create ]
  #  resources :phone_books
  #end
  
  # Twilio API extension
  namespace :twilio do
    resource :inbound_call, only: [ :show, :create ], defaults: { format: 'xml' }
    resource :call_update, only: [ :show, :create ], defaults: { format: 'xml' }
    resource :inbound_sms, only: [ :show, :create ], defaults: { format: 'xml' }
    resource :sms_update, only: [ :show, :create ], defaults: { format: 'xml' }
  end
  
  # Sidekiq!
  #   require 'sidekiq/web'
  #   authenticate :user do #, lambda { |u| u.admin? } do
  #     mount Sidekiq::Web => '/sidekiq'
  #   end

#   resources :organizations, only: [:index] do
#     member do
#       get 'shadow', action: 'shadow' #, as: 'shadow'
#     end
#   end

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
  root :to => 'organizations#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
