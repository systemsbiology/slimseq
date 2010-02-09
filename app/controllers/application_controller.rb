# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Authentication, either using restful_authentication or using rubycas-server
  include AuthenticatedSystem 
 
  # Homebrew, very simple authorization
  include Authorization

  # Use proper HTTP status code and response format for common exceptions
  unless ActionController::Base.consider_all_requests_local
    rescue_from 'ActionController::UnknownAction', :with => :unknown_action
    rescue_from 'ActionController::MethodNotAllowed', :with => :invalid_method
    rescue_from 'ActiveSupport::JSON::ParseError', :with => :bad_json
  end

  # Exception Notifier plugin
  include ExceptionNotifiable
  
  # filter passwords out of logs
  filter_parameter_logging "password"
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => 'c1e0cc867735b750b889ccc506dd107f'
  
  protected

    def invalid_method(exception)
      error_with_status(exception, :method_not_allowed, 500)
    end

    def bad_json(exception)
      error_with_status(exception, :unprocessable_entity, 500)
    end

    def unknown_action(exception)
      error_with_status(exception, :not_found, 404)
    end

    def error_with_status(exception, status, html_error_file)
      respond_to do |format|
        format.html { render_optional_error_file(html_error_file) }
        format.xml  { render :xml => {:error => exception.to_s}, :status => status }
        format.json  { render :json => {:error => exception.to_s}, :status => status }
      end
    end
end
