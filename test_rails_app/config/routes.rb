ActionController::Routing::Routes.draw do |map|  
  
  #
  # some sample routes taken from the comments in the original boilerplate
  #
  
  map.resources :users do |users|
    users.resources :articles, :collection => {:recent => :get}
    users.resource :profile
  end
  
  map.resources :pages, :member => {:summary => :get, :toggle_visibility => :post}
  
  map.namespace :admin do |admin|
      admin.resources :products
  end

  #
  # described_routes will use this as the base URI if present, otherwise
  # it returns only relative paths
  #
  map.root :controller => "welcome"
  
  #
  # described_routes at runtime
  #
  map.resources :described_routes, :controller => "described_routes/rails"
end
