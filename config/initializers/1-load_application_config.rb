APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/application.yml")[RAILS_ENV]
#AppConfig.load(nil,nil)
AppConfig.load("#{RAILS_ROOT}/config/application.yml",RAILS_ENV)

