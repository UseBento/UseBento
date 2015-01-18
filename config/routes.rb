Rails.application.routes.draw do
  devise_for :users
  get  'services/select'
  get  'services/add'
  get  'projects/new/:name',          to: 'services#create',      as: 'service'
  get  'projects/list',               to: 'projects#list'
  get  'projects/:id',                to: 'projects#view',        as: 'project'
  post 'projects/new',                to: 'projects#new'         
  get  'projects/:id/edit',           to: 'projects#edit'         
  post 'projects/:project_id/message', to: 'messages#post_message'         
  get  'attachment/:project_id/:message_id/:attachment_id/:filename', to: 'messages#view_attachment'

  root 'welcome#index'
  get  'contact',                     to: 'application#contact'
  post 'send_contact',                to: 'application#send_contact'
  get  'apply',                       to: 'application#apply'
  get  'agencies',                    to: 'application#agencies'
  get  'payments/checkout/:project_id/:percent',           
       to: 'payments#checkout'
  post 'payments/checkout/:project_id/:percent/process',   to: 'payments#process_payment'

  devise_scope :user do
    get  'user_exists',                 to: 'users#exists'
    get  'profile',                     to: 'users#profile'
    post 'profile/update',              to: 'users#update_profile'
  
    post 'users/sign_up',               to: 'users#sign_up'
    post 'users/log_in',                to: 'users#log_in'
    post 'users/reset',                 to: 'users#reset'

    get  'popups/login',                to: 'users#login_popup'
    get  'popups/sign_up',              to: 'users#sign_up_popup'
    get  'popups/password',             to: 'users#password_popup'
    get  'popups/password_reset_sent',  to: 'users#password_reset_sent_popup'
  end
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
  #       get 'sold'r
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
