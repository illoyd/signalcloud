web: bundle exec unicorn_rails -p $PORT -c ./config/unicorn.rb 2>&1
worker: bundle exec sidekiq -C ./config/sidekiq.yml 2>&1
