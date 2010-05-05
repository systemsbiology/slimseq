# only configure RubyCAS-client if it's configured in the application.yml configuration
begin
  if(AppConfig.rubycas_server)
    # rubycas-client gem
    require 'casclient'
    require 'casclient/frameworks/rails/filter'
    
    CASClient::Frameworks::Rails::Filter.configure(
                                                   :cas_base_url => AppConfig.rubycas_server
                                                   )
  end
end

