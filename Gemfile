source 'https://rubygems.org'

ruby "2.1.2"
gem 'rails', '~> 4.2.0.beta1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'
gem 'pg'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.0.beta1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', :platforms => :ruby

# Adding twitter bootstrap tools
gem 'bootstrap-sass', '~> 3.2.0'
gem 'bootstrap-sass-extras'
gem 'autoprefixer-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Use Rails Html Sanitizer for HTML sanitization
gem 'rails-html-sanitizer', '~> 1.0'

group :development, :test do
  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console', '~> 2.0.0.beta2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

# Use unicorn as the app server
gem 'unicorn'

# Add sinatra for sidekiq
gem 'sinatra', '>= 1.3.0', :require => nil

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

#
# Additional gems
gem 'active_model_serializers', '~> 0.8.0'
gem 'haml'
gem 'devise', git: 'git://github.com/plataformatec/devise.git', branch: 'lm-rails-4-2'
gem 'devise-async'
gem 'devise_invitable'
gem 'cancancan', '~> 1.8'
gem 'attr_encrypted', '~> 1.3.2'
gem 'kaminari'
gem 'bootstrap-kaminari-views'
gem 'stringex'
gem 'httparty'
gem 'api_smith'
gem 'twitter_bootstrap_form_for', :git => 'git://github.com/stouset/twitter_bootstrap_form_for.git', :branch => 'bootstrap-2.0'
gem 'workflow'
gem 'countries'
gem 'countries-phone_numbers'
gem 'country_select'
gem 'gretel'
gem 'chartkick'
gem 'hightop'
gem 'groupdate'
gem 'active_median'
gem 'responders'
gem 'going_postal'

#
# Temporary or deprecated gems - these should be removed!
# Hooray! Nothing here!

#
# Internal services (e.g. queues, caches)
gem 'dalli'
gem 'redis'
gem 'sidekiq', '~> 3.2'
#gem 'sidetiq'

#
# External services (e.g. telephony, accounting)
gem 'twilio-ruby'
gem 'ruby-freshbooks'

#
# Test and development gems
group :test, :development do
  gem "rspec-rails"
end

#
# Test gems
group :test do
	gem 'shoulda-matchers'
	gem 'rspec-sidekiq'
	gem 'rspec-its'
	gem 'vcr'
	gem 'webmock', "~> 1.11.0"
	gem 'factory_girl'
	gem 'fuubar'
  gem 'simplecov', :require => false
  gem 'hashdiff'
  gem 'faker'
end

#
# Production gems
group :production do
  gem 'rails_12factor'
  gem 'newrelic_rpm'
  gem 'lograge'
end
