# only configure RubyCAS-client if it's configured in the application.yml configuration
if(APP_CONFIG && APP_CONFIG['rubycas_server'])
  # rubycas-client gem
  require 'casclient'
  require 'casclient/frameworks/rails/filter'

  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url => APP_CONFIG['rubycas_server']
  )
end
