ActionController::Routing::Routes.draw do |map|
  map.resources :external_services

  map.resources :eland_parameter_sets

  # backward compatibility with bookmarked login page
  map.connect 'session/new', :controller => "welcome", :action => "home"

  # logout
  map.connect 'logout', :controller => "sessions", :action => "destroy"

  # SLIM* Authorization routes
  map.resources :sessions
  map.resources :lab_groups
  map.resources :registrations
  map.resources :users do |users|
    users.resources :lab_memberships, :name_prefix => "user_"
  end
  map.resources :lab_memberships

  # load routes from naming schemer plugin
  # Use with Rails 2.3
  #map.from_plugin :naming_schemer
  map.resources :naming_schemes

  # SLIMseq routes
  map.resources :pipeline_results

  # samples hiearchy 
  map.connect 'projects/:id/new_sample', :controller=>'projects', :action=>'new_study'
  map.connect 'projects/explore', :controller=>'projects', :action=>'explore'
  map.connect 'projects/explore_data', :controller=>'projects', :action=>'explore_data'
  map.resources :projects
  map.resources :studies
  map.resources :experiments

  map.resources :pipeline_runs
  
  map.resources :flow_cell_lanes

  # add in some other urls to samples/
  map.connect 'samples/browseh/:project/:study/:experiment', :controller=>'samples', :action=>'browseh'
  map.connect 'samples/browseh/:project/:study', :controller=>'samples', :action=>'browseh'
  map.connect 'samples/browseh/:project', :controller=>'samples', :action=>'browseh'
  map.connect 'samples/browseh', :controller=>'samples', :action=>'browseh'

  # make sample_mixtures actions appear under the /samples URL
  map.resources :sample_mixtures, :as => "samples", :except => [:index, :show],
    :collection => {:browse => :post, :search => :get, :all => :get}
  map.resources :sample_mixtures
  map.resources :samples, :only => [:index, :show]
  
  map.resources :sample_sets, :only => [:new, :create]
  
  map.resources :instruments

  map.resources :sequencing_runs do |sequencing_runs|
    sequencing_runs.resources :gerald_configurations, :name_prefix => "sequencing_run_"
  end

  map.connect 'gerald_configurations/:sequencing_run_name',
    :controller => 'gerald_configurations', :action => 'default',
    :sequencing_run_name => /.*_.*_.*(_.*)*/
  
  map.resources :flow_cells

  map.resources :sample_prep_kits

  map.resources :reference_genomes

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
end
