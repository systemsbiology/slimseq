# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_slimseq_session',
    :secret      => 'f60f394add7aa3c74c2529e823cb87fc30780205e8f058b2fdd0e08a26d60f23c53f5fbc4142a58df75ef237b8ff3f79c9d5b571bf372d1cb70f28818aae3975'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use cookie-based store, which works nicely with protect_from_forgery in application.rb
  config.action_controller.session_store = :cookie_store
  
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Required gems
  config.gem "json", :version => '1.1.3'
  config.gem "parseexcel", :version => '0.5.2'
  config.gem "rest-client", :lib => "rest_client", :version => '0.8.2'
  config.gem "hpricot", :version => '0.6.161'
  config.gem "nokogiri", :version => '1.2.3'
  config.gem "rubycas-client", :version => '2.1.0'
  config.gem "highline", :version => '1.4.0'
end

AUTHENTICATION_SALT = 'mmm_kosher_rocks' unless defined? AUTHENTICATION_SALT

# Exception Notifier plugin configuration
# Hackish way of handling the case where the database is empty
begin
  if( ENV["RAILS_ENV"] == "test" )
    ExceptionNotifier.exception_recipients = "admin@example.com"
  else
    ExceptionNotifier.exception_recipients = SiteConfig.administrator_email
  end
rescue
  ExceptionNotifier.exception_recipients = "admin@example.com"
end
ExceptionNotifier.sender_address =
    %("Application Error" <slimseq@#{`hostname`.strip}>)

