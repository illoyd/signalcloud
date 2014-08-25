# Assign the master APPLICATION_PEPPER_KEY here
DIGEST_REALM            = 'SignalCloud'
ALLOW_ORG_CREATION      = ( (ENV['ALLOW_ORG_CREATION'] || 'false').downcase == 'true' )
ALLOW_USER_REGISTRATION = ( (ENV['ALLOW_USER_REGISTRATION'] || 'false').downcase == 'true' )
