##
# Extend the Freshbooks API to include a direct request to the currently configured account
module Freshbooks
  ##
  # Request the current account; expects +ENV['FRESHBOOKS_API_ENDPOINT=']+ and +ENV['FRESHBOOKS_API_TOKEN']+
  # to be defined in the environment.
  def self.account
    @@client ||= FreshBooks::Client.new( ENV['FRESHBOOKS_API_ENDPOINT'], ENV['FRESHBOOKS_API_TOKEN'] )
  end
  
  def self.system_info( reset=false )
    @@system_info = nil if reset
    @@system_info ||= account.system.current['system']
  end
  
  def self.requests( reset=false )
    (system_info(reset))['api']['requests']
  end
  
  def self.request_limit( reset=false )
    (system_info(reset))['api']['request_limit']
  end
  
  def self.reset
    @@system_info = nil
    @@client = nil
  end
end
 