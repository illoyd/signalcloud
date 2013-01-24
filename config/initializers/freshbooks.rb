##
# Extend the Freshbooks API to include a direct request to the currently configured account
module Freshbooks
  ##
  # Request the current account; expects +ENV['FRESHBOOKS_URL']+ and +ENV['FRESHBOOKS_API_TOKEN']+
  # to be defined in the environment.
  def self.account
    @@client ||= FreshBooks::Client.new( ENV['FRESHBOOKS_URL'], ENV['FRESHBOOKS_API_TOKEN'] )
  end
end
 