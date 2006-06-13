require 'login_engine'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include LoginEngine
  include UserEngine
      
  helper :user
  model :user

  before_filter :authorize_action
end