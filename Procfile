web: bundle exec unicorn_rails -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -C ./config/sidekiq.yml
webworker: bundle exec unicorn_rails -p $PORT -c ./config/unicorn+sidekiq.rb
redis: redis-server
