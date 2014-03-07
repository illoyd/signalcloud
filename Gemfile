source 'https://rubygems.org'

ruby "2.1.0"
gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'
gem 'pg', '~> 0.17.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  
  # Adding twitter bootstrap tools
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Add sinatra for sidekiq
gem 'sinatra', '>= 1.3.0', :require => nil

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

# Additional gems
gem 'attribute_normalizer'
gem 'active_model_serializers'
gem 'sidekiq'
gem 'haml'
gem 'twilio-ruby'
gem 'devise', '~> 3.0.0'
gem 'devise-async'
gem 'devise_invitable'
gem 'cancan'
gem 'attr_encryptor', "~> 2.0.0"
gem 'kaminari'
gem 'phony', :git => 'git://github.com/illoyd/phony.git'
gem 'stringex'
gem 'ruby-freshbooks'
gem 'httparty'
gem 'api_smith'
gem 'twitter_bootstrap_form_for', :git => 'git://github.com/stouset/twitter_bootstrap_form_for.git', :branch => 'bootstrap-2.0'
gem 'countries'
gem 'country_select'
gem 'workflow'
gem 'strong_parameters'
gem 'paperclip'
gem 'roo'
gem 'lograge'
gem 'liquid'
gem 'google_drive'

# Additional authentication gems
gem 'omniauth'
gem 'omniauth-google-oauth2'

group :test, :development do
  gem "rspec-rails", "~> 2.0"
end

group :test do
	gem 'shoulda-matchers'
	gem 'rspec-sidekiq'
	gem 'vcr'
	gem 'webmock', "~> 1.11.0"
	gem 'factory_girl'
	gem 'fuubar'
  gem "ZenTest", "~> 4.4.2"
  gem "autotest-rails", "~> 4.1.0"
  gem 'simplecov', :require => false
end

group :production do
  gem 'newrelic_rpm'
end
