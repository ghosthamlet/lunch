Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  get '/details' => 'welcome#details'
  get '/healthy' => 'welcome#healthy'
  get '/session_status' => 'welcome#session_status'
  get '/disclaimer-reuters' => 'error#not_found', as: :disclaimer_reuters
  get '/online-security' => 'error#not_found', as: :online_security
  get '/grid_demo' => 'welcome#grid_demo'

  get '/dashboard' => 'dashboard#index'

  get '/dashboard/quick_advance_rates' => 'dashboard#quick_advance_rates'

  post '/dashboard/quick_advance_preview' => 'dashboard#quick_advance_preview'

  post '/dashboard/quick_advance_perform' => 'dashboard#quick_advance_perform'

  get '/dashboard/current_overnight_vrc' => 'dashboard#current_overnight_vrc'

  scope 'reports', as: :reports do
    get '/' => 'reports#index'
    get '/capital-stock-activity' => 'reports#capital_stock_activity'
    get '/borrowing-capacity' => 'reports#borrowing_capacity'
    get '/settlement-transaction-account' => 'reports#settlement_transaction_account'
    get '/advances' => 'reports#advances_detail'
    get '/historical-price-indications' => 'reports#historical_price_indications'
    get '/current-price-indications' => 'reports#current_price_indications'
    get '/interest-rate-resets' => 'reports#interest_rate_resets'
    get '/letters-of-credit' => 'reports#letters_of_credit'
    get '/putable-advance-parallel-shift-sensitivity' => 'reports#parallel_shift', as: :parallel_shift
    get '/forward-commitments' => 'reports#forward_commitments'
    get '/account-summary' => 'reports#account_summary'
    get '/todays-credit' => 'reports#todays_credit'

    get '/authorizations'                => 'error#not_found'
    get '/capital-stock-and-leverage'    => 'error#not_found'
    get '/cash-projections'              => 'error#not_found'
    get '/current-securities-position'   => 'error#not_found'
    get '/dividend-statement'            => 'error#not_found'
    get '/monthly-securities-position'   => 'error#not_found'
    get '/mortgage-collateral-update'    => 'error#not_found'
    get '/securities-services-statement' => 'reports#securities_services_statement'
    get '/trial-balance'                 => 'error#not_found'
    get '/securities-transactions'       => 'error#not_found'
  end

  get '/advances' => 'advances#index'
  get '/advances/manage-advances' => 'advances#manage_advances'

  get '/settings' => 'error#not_found'
  post '/settings/save' => 'settings#save'
  get '/settings/two-factor' => 'settings#two_factor'
  post '/settings/two-factor/pin' => 'settings#reset_pin'
  post '/settings/two-factor/resynchronize' => 'settings#resynchronize'
  get '/settings/users' => 'settings#users'
  post '/settings/users/:id/lock' => 'settings#lock', as: 'user_lock'
  post '/settings/users/:id/unlock' => 'settings#unlock', as: 'user_unlock'
  get '/settings/users/:id' => 'settings#edit_user', as: 'user'
  patch '/settings/users/:id' => 'settings#update_user'
  get '/settings/users/:id/confirm_delete' => 'settings#confirm_delete', as: 'user_confirm_delete'
  delete '/settings/users/:id' => 'settings#delete_user'
  get '/settings/expired-password' => 'settings#expired_password', as: :user_expired_password
  put '/settings/expired-password' => 'settings#update_expired_password'
  get '/settings/password' => 'settings#change_password', as: :settings_password
  put '/settings/password' => 'settings#update_password'

  get '/jobs/:job_status_id' => 'jobs#status', as: 'job_status'
  get '/jobs/:job_status_id/download' => 'jobs#download', as: 'job_download'
  get '/jobs/:job_status_id/cancel' => 'jobs#cancel', as: 'job_cancel'

  scope 'corporate_communications/:category' do
    resources :corporate_communications, only: :show, as: :corporate_communication
    get '/' => 'corporate_communications#category', as: :corporate_communications
  end

  scope 'resources' do
    get '/business-continuity' => 'resources#business_continuity'
    get '/forms' => 'resources#forms'
    get '/guides' => 'resources#guides'
    get '/download/:file' => 'resources#download', as: :resources_download
  end

  scope 'products' do
    get '/summary' => 'products#index', as: :product_summary
    get '/letters-of-credit' => 'error#not_found'
    get '/community_programs' => 'error#not_found'
    get '/product-mpf-pfi' => 'error#not_found', as: :product_mpf_pfi
    scope 'advances' do
      get 'adjustable-rate-credit' => 'products#arc', as: :arc
      get 'advances-for-community-enterprise' => 'error#not_found', as: :ace
      get 'amortizing' => 'products#amortizing', as: :amortizing
      get 'arc-embedded' => 'products#arc_embedded', as: :arc_embedded
      get 'callable' => 'products#callable', as: :callable
      get 'choice-libor' => 'products#choice_libor', as: :choice_libor
      get 'community-investment-program' => 'error#not_found', as: :cip
      get 'auction-indexed' => 'products#auction_indexed', as: :auction_indexed
      get 'fixed-rate-credit' => 'products#frc', as: :frc
      get 'frc-embedded' => 'products#frc_embedded', as: :frc_embedded
      get 'knockout' => 'products#knockout', as: :knockout
      get 'mortgage-partnership-finance' => 'products#mpf', as: :mpf
      get 'other-cash-needs' => 'products#ocn', as: :ocn
      get 'putable' => 'products#putable', as: :putable
      get 'securities-backed-credit' => 'products#sbc', as: :sbc
      get 'variable-rate-credit' => 'products#vrc', as: :vrc
    end

  end

  devise_scope :user do
    get '/' => 'users/sessions#new', :as => :new_user_session
    post '/' => 'users/sessions#create', :as => :user_session
    delete 'logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get 'logged-out' => 'members#logged_out' 
    get '/member' => 'members#select_member', :as => :members_select_member
    post '/member' => 'members#set_member', :as => :members_set_member
    get 'member/terms' => 'members#terms', :as => :terms
    post 'member/terms' => 'members#accept_terms', :as => :accept_terms
    get 'member/password' => 'users/passwords#new', as: :new_user_password
    post 'member/password' => 'users/passwords#create', as: :user_password
    get 'member/password/reset' => 'users/passwords#edit', as: :edit_user_password
    put 'member/password' => 'users/passwords#update'
    get '/terms-of-use' => 'members#terms_of_use', as: :terms_of_use
    get '/contact' => 'members#contact', as: :contact
  end
  devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' }, :skip => [:sessions, :passwords]

  root 'users/sessions#new'

  get '/error' => 'error#standard_error' unless Rails.env.production?
  get '/maintenance' => 'error#maintenance' unless Rails.env.production?
  get '/not-found' => 'error#not_found' unless Rails.env.production?

  # This catchall route MUST be listed here last to avoid catching previously-named routes
  get '*unmatched_route' => 'error#not_found'

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
