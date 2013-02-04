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
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

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

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.default_cassette_options = { :record => :new_episodes, match_requests_on: [:method, :uri, :query, :body] }
  c.hook_into :webmock
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

def enqueue_and_work_jobs( jobs, options={} )
  jobs = [ jobs ] if !jobs.is_a?(Array)
  options.reverse_merge! existing_jobs: 0, queued_jobs: jobs.size, remaining_jobs: 0, successes: jobs.size, failures: 0, expected_error: nil
  enqueue_jobs( jobs, options )
  work_jobs( jobs.size, options )
end

def enqueue_jobs( jobs, options={} )
  jobs = [ jobs ] if !jobs.is_a?(Array)
  options.reverse_merge! existing_jobs: 0, queued_jobs: jobs.size
  expect {
    jobs.each { |job| Delayed::Job.enqueue job }
  }.to change{Delayed::Job.count}.from(options[:existing_jobs]).to(options[:queued_jobs])
end

def work_jobs( jobs, options={} )
  options.reverse_merge! successes: jobs, failures: 0, queued_jobs: jobs, remaining_jobs: 0, expected_error: nil
  expect {
    if options[:expected_error].nil?
      expect { @work_results = Delayed::Worker.new.work_off(jobs) }.to_not raise_error
    else
      expect { @work_results = Delayed::Worker.new.work_off(jobs) }.to raise_error(options[:expected_error])
    end
    @work_results.should eq( [ options[:successes], options[:failures] ] ) # One success, zero failures
  }.to change{Delayed::Job.count}.from(options[:queued_jobs]).to(options[:remaining_jobs])
end

def rand_datetime(from, to=Time.now)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

def rand_datetime_lastmonth(from=nil, to=nil)
  from ||= 1.month.ago.beginning_of_month
  to ||= from.end_of_month
  Time.at rand_in_range(from.to_f, to.to_f)
end

def rand_in_range(from, to)
  rand * (to - from) + from
end

def rand_f( min, max )
  rand * (max-min) + min
end

def rand_i( min, max )
  min = min.to_i
  max = max.to_i
  rand(max-min) + min
end

def random_us_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_ca_number()
  '1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_uk_number()
  '44%04d%03d%03d' % [ rand_i(2000, 9999), rand_i(000, 999), rand_i(000, 999) ]
end

def random_cost( min=0.01, max=99.99, round=2 )
  rand_f(min, max).round(round)
end

alias random_price random_cost
