# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # RESTful authentication
  include AuthenticatedSystem
  
  # Homebrew, very simple authorization
  include Authorization

  # Exception Notifier plugin
  include ExceptionNotifiable
  
  # filter passwords out of logs
  filter_parameter_logging "password"

  alias :rescue_action_locally :rescue_action_in_public
end