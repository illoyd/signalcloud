Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDIS_URL'] }
  config.logger.level = Logger::WARN if Rails.env.production?
  config.logger.level = Logger::ERROR if Rails.env.test?
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDIS_URL'] }
  config.logger.level = Logger::ERROR if Rails.env.test?
end
