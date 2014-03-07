Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://us.signalcloudapp.com:6379', :namespace => 'signalcloud' }
  config.logger.level = Logger::WARN if Rails.env.production?
  config.logger.level = Logger::ERROR if Rails.env.test?
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://us.signalcloudapp.com:6379', :namespace => 'signalcloud' }
  config.logger.level = Logger::ERROR if Rails.env.test?
end
