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

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  
  # Mix-in the FactoryGirl methods
  config.include FactoryGirl::Syntax::Methods

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

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
  
  # Include auth digest helper
  config.include AuthSpecHelpers, :type => :controller
end

FactoryGirl.find_definitions

##
# Authenticate helper
class ActionController::TestCase
 require 'digest/md5'
 #include Devise::TestHelpers

  def authenticate_with_http_digest(user = nil, password = nil, realm = nil)
    ActionController::Base.class_eval { include ActionController::Testing }

    @controller.instance_eval %Q(
      alias real_process_with_new_base_test process_with_new_base_test

      def process_with_new_base_test(request, response)
        credentials = {
      	  :uri => request.url,
      	  :realm => "#{realm}",
      	  :username => "#{user}",
      	  :nonce => ActionController::HttpAuthentication::Digest.nonce(request.env['action_dispatch.secret_token']),
      	  :opaque => ActionController::HttpAuthentication::Digest.opaque(request.env['action_dispatch.secret_token'])
        }
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Digest.encode_credentials(request.request_method, credentials, "#{password}", false)

        real_process_with_new_base_test(request, response)
      end
    )
  end
end

def build_authenticated_request_url( url, username=nil, password=nil )
  temp_path = url.dup # twilio_inbound_sms_url
  unless username.blank?
    auth_string = username
    auth_string += ':'+password unless password.blank?
    temp_path.gsub!( /(https?:\/\/)/, '\1' + auth_string + '@' )
  end
  temp_path
end

def build_twilio_signature( url, account=nil, post_params={} )
  url = build_authenticated_request_url( url, account.account_sid, account.auth_token )
  account.twilio_validator.build_signature_for( url, post_params )
end

def inject_twilio_signature( url, account=nil, post_params={} )
  request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( url, account, post_params )
end
  
def enqueue_and_work_jobs( jobs, options={} )
  jobs = [ jobs ] unless jobs.is_a?(Array)
  #options.reverse_merge! existing_jobs: 0, queued_jobs: jobs.size, remaining_jobs: 0, successes: jobs.size, failures: 0, expected_error: nil
  enqueue_jobs( jobs, options )
  work_jobs( jobs.size, options )
end

def enqueue_jobs( jobs, options={} )
  jobs = [ jobs ] unless jobs.is_a?(Array)
  options.reverse_merge! existing_jobs: 0, queued_jobs: jobs.size
  expect {
    jobs.each { |job| Delayed::Job.enqueue job }
  }.to change{Delayed::Job.count}.from(options[:existing_jobs]).to(options[:queued_jobs])
end

def work_jobs( job_count, options={} )
  options.reverse_merge! successes: job_count, failures: 0, queued_jobs: job_count, remaining_jobs: 0, expected_error: nil
  expect {
    if options[:expected_error].nil?
      expect { @work_results = Delayed::Worker.new.work_off(job_count) }.to_not raise_error
    else
      expect { @work_results = Delayed::Worker.new.work_off(job_count) }.to raise_error(options[:expected_error])
    end
    @work_results.should eq( [ options[:successes], options[:failures] ] ) # One success, zero failures
  }.to change{Delayed::Job.count}.from(options[:queued_jobs]).to(options[:remaining_jobs])
end
