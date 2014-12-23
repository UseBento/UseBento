Rails.application.routes.draw do
  devise_for :users
  get  'services/select'
  get  'services/add'
  get  'projects/new/:name',          to: 'services#create',      as: 'service'
  get  'projects/:id',                to: 'projects#view',        as: 'project'
  post 'projects/new',                to: 'projects#new'         

  root 'welcome#index'
  get  'contact',                     to: 'application#contact'
  get  'apply',                       to: 'application#apply'
  get  'agencies',                    to: 'application#agencies'
  post 'users/sign_up',               to: 'users#sign_up'
  get  'popups/login',                to: 'users#login_popup'
  get  'popups/sign_up',              to: 'users#sign_up_popup'
  get  'popups/password',             to: 'users#password_popup'
  get  'popups/password_reset_sent',  to: 'users#password_reset_sent_popup'
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
