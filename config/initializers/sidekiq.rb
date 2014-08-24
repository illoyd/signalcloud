##
# Configure server to connect to Redis Cloud
Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISCLOUD_URL'] }
  config.logger.level = Logger::WARN if Rails.env.production?
  config.logger.level = Logger::ERROR if Rails.env.test?
end

##
# Configure clients to connect to Redis Cloud
Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISCLOUD_URL'] }
  config.logger.level = Logger::ERROR if Rails.env.test?
end
