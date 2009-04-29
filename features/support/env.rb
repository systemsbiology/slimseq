# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatters/unicode'
require 'webrat/rails'
require 'cucumber/rails/rspec'

# Load site-wide config via fixtures
Fixtures.create_fixtures("spec/fixtures", "site_config")

# use FixtureReplacement plugin
include FixtureReplacement
