Rails.application.routes.draw do

  devise_for :users

  resources :teams do
    resources :conversations, only: [:index, :new, :create]
    resources :invoices,      only: [:index, :new, :create]
    resources :journals,      only: [:index, :new, :create]
    resources :phone_books,   only: [:index, :new, :create]
    resources :phone_numbers, only: [:index, :new, :create]
    resources :stencils,      only: [:index, :new, :create]
    resources :users,         only: [:index, :new, :create]
  end
  
  resources :conversations,   only: [:show, :edit, :update]
  resources :invoices,        only: [:show, :edit, :update]
  resources :journals,        only: [:show, :edit, :update]
  resources :phone_books,     only: [:show, :edit, :update]
  resources :phone_numbers,   only: [:show, :edit, :update] do
    resources :conversations, only: [:index]
    member do
      post   :purchase
      delete :release
    end
  end
  resources :stencils,        only: [:show, :edit, :update]
  resources :users,           only: [:show, :edit, :update]
  
  resources :memberships,     only: [:create, :update, :destroy]
  resources :phone_book_entries, only: [:create, :update, :destroy]
  
  resources :if_clauses,                only: [:destroy]
  resources :if_starting_clauses,       only: [:create, :update, :destroy]

  resources :then_clauses,              only: [:destroy]
  resources :then_send_message_clauses, only: [:create, :update, :destroy]
  
  root to: "teams#index"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
