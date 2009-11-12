Cucumber::Rails.use_transactional_fixtures

Webrat.configure do |config|
  config.mode = :rails
end

