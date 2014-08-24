# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run SignalCloud::Application

#require 'sidekiq/web'
#run Rack::URLMap.new(
#    "/" => Rails.application,
#    "/sidekiq" => Sidekiq::Web
#)
