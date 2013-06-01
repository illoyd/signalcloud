source 'https://rubygems.org'

ruby "2.0.0"
gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'
gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

# Additional gems
gem 'active_model_serializers'
gem 'delayed_job_active_record'
gem 'haml'
gem 'twilio-ruby'
gem 'devise'
gem 'devise-async'
gem 'devise_invitable'
gem 'cancan'
gem 'attr_encryptor', :git => 'git://github.com/danpal/attr_encryptor.git'
gem 'kaminari'
gem 'phony', :git => 'git://github.com/illoyd/phony.git'
gem 'stringex'
gem 'ruby-freshbooks'
gem 'httparty'
gem 'api_smith'
gem 'twitter_bootstrap_form_for', :git => 'git://github.com/stouset/twitter_bootstrap_form_for.git', :branch => 'bootstrap-2.0'
gem 'country_select'
gem 'countries'
gem 'workflow'

group :test, :development do
  gem "rspec-rails", "~> 2.0"
end

group :test do
	gem 'shoulda-matchers'
	gem 'vcr'
	gem 'webmock', "~> 1.11.0"
	gem 'factory_girl'
	gem 'fuubar'
  gem "ZenTest", "~> 4.4.2"
  gem "autotest-rails", "~> 4.1.0"
  gem 'simplecov', :require => false
end

group :production do
  gem 'lograge'
  gem 'newrelic_rpm'
end
