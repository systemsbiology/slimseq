ActionController::Routing::Routes.draw do |map|
  map.resources :pipeline_runs

  map.resources :registrations
  
  map.resources :flow_cell_lanes

  map.resources :samples
  
  map.resources :instruments
  
  map.resources :naming_schemes

  map.resources :sequencing_runs do |sequencing_runs|
    sequencing_runs.resources :gerald_configurations, :name_prefix => "sequencing_run_"
  end

  map.resources :flow_cells

  map.resources :sample_prep_kits

  map.resources :reference_genomes

  map.resources :users do |users|
    users.resources :lab_memberships, :name_prefix => "user_"
  end

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome", :action => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.resource :session
end
