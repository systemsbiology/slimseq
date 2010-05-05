ActionController::Routing::Routes.draw do |map|
  map.connect '/post_pipelines/help', :controller=>:post_pipelines, :action=>:help
  map.resources :post_pipelines, :member=>{:launch=>:get}
end
