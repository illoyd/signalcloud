require 'simplecov'
SimpleCov.start 'rails'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
require 'sidekiq/testing'

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
  
  # Filter
  config.filter_run :focus => true
  config.filter_run_excluding :skip
  config.run_all_when_everything_filtered = true

  # Include auth digest helper
  config.include AuthSpecHelpers, :type => :controller

  # Include devise helpers
  config.include Devise::TestHelpers, :type => :controller
  config.extend ControllerMacros, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
  
  # Mix-in the FactoryGirl methods
  config.include FactoryGirl::Syntax::Methods

  config.treat_symbols_as_metadata_keys_with_true_values = true

end

FactoryGirl.find_definitions

# ##
# # Authenticate helper
# class ActionController::TestCase
#  require 'digest/md5'
#  #include Devise::TestHelpers
# 
#   def authenticate_with_http_digest(user = nil, password = nil, realm = nil)
#     ActionController::Base.class_eval { include ActionController::Testing }
# 
#     @controller.instance_eval %Q(
#       alias real_process_with_new_base_test process_with_new_base_test
# 
#       def process_with_new_base_test(request, response)
#         credentials = {
#       	  :uri => request.url,
#       	  :realm => "#{realm}",
#       	  :username => "#{user}",
#       	  :nonce => ActionController::HttpAuthentication::Digest.nonce(request.env['action_dispatch.secret_token']),
#       	  :opaque => ActionController::HttpAuthentication::Digest.opaque(request.env['action_dispatch.secret_token'])
#         }
#         request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Digest.encode_credentials(request.request_method, credentials, "#{password}", false)
# 
#         real_process_with_new_base_test(request, response)
#       end
#     )
#   end
# end

def build_authenticated_request_url( url, username=nil, password=nil )
  temp_path = url.dup # twilio_inbound_sms_url
  unless username.blank?
    auth_string = username
    auth_string += ':'+password unless password.blank?
    temp_path.gsub!( /(https?:\/\/)/, '\1' + auth_string + '@' )
  end
  temp_path
end

def build_twilio_signature( url, organization=nil, post_params={} )
  url = build_authenticated_request_url( url, organization.sid, organization.auth_token )
  organization.communication_gateways.first.twilio_validator.build_signature_for( url, post_params )
end

def inject_twilio_signature( url, organization=nil, post_params={} )
  request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( url, organization, post_params )
end
