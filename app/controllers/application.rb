# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Authentication, either using restful_authentication or using rubycas-server
  include AuthenticatedSystem 
 
  # Homebrew, very simple authorization
  include Authorization

  # Exception Notifier plugin
  include ExceptionNotifiable
  
  # filter passwords out of logs
  filter_parameter_logging "password"
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'c1e0cc867735b750b889ccc506dd107f'
end
