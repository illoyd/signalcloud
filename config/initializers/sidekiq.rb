Sidekiq.configure_server do |config|
  config.redis = { :url => 'redis://us.signalcloudapp.com:6379', :namespace => 'signalcloud' }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => 'redis://us.signalcloudapp.com:6379', :namespace => 'signalcloud' }
end
