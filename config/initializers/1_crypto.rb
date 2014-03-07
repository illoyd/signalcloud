# Assign the master APPLICATION_PEPPER_KEY here
ATTR_ENCRYPTED_SECRET   = ENV['ATTR_ENCRYPTED_SECRET']
DIGEST_REALM            = 'SignalCloud'
ALLOW_ORG_CREATION      = ( (ENV['ALLOW_ORG_CREATION'] || 'false').downcase == 'true' )
ALLOW_USER_REGISTRATION = ( (ENV['ALLOW_USER_REGISTRATION'] || 'false').downcase == 'true' )

module Workflow
  class Specification
    def valid_state_names
      state_names + state_names.map{|state| state.to_s}
    end
  end
end