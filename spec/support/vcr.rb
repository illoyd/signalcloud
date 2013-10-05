VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.default_cassette_options = { :record => :once, match_requests_on: [:method, :uri, :query, :body] }
  c.hook_into :webmock
  c.ignore_hosts 'us.signalcloudapp.com', 'eu.signalcloudapp.com', 'requestb.in'

  c.filter_sensitive_data('{{TWILIO_MASTER_SID}}')   { ENV['TWILIO_MASTER_ACCOUNT_SID'] }
  c.filter_sensitive_data('{{TWILIO_MASTER_TOKEN}}') { ENV['TWILIO_MASTER_AUTH_TOKEN'] }
  c.filter_sensitive_data('{{TWILIO_TEST_SID}}')     { ENV['TWILIO_TEST_ACCOUNT_SID'] }
  c.filter_sensitive_data('{{TWILIO_TEST_TOKEN}}')   { ENV['TWILIO_TEST_AUTH_TOKEN'] }

  c.configure_rspec_metadata!

end
