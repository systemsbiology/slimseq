# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # RESTful authentication
  include AuthenticatedSystem
  
  # Homebrew, very simple authorization
  include Authorization

  # filter passwords out of logs
  filter_parameter_logging "password"
end