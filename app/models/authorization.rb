class Authorization < ActiveRecord::Base
  belongs_to :user, inverse_of: :authorizations

  attr_encrypted :username, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :uid,      key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :token,    key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :secret,   key: ATTR_ENCRYPTED_SECRET

  before_save :build_oauth_hash
  after_create :fetch_details

  def fetch_details
  end
  
  def self.provider_class( provider )
    case provider
      when 'google_oauth2'; GoogleAuthorization
      else; self
    end
  end
  
  def self.for_provider( provider, auth )
    logger.warn "Getting authorisation for #{provider} with auth: #{auth}"
    provider_class(provider).find_by_oauth_tokens( auth.uid, auth.credentials.token, auth.credentials.secret ).first_or_initialize
  end
  
  def self.oauth_hash( uid, token, secret )
    Digest::SHA1.hexdigest("#{uid}:#{token}:#{secret}")
  end
  
  def self.find_by_oauth_tokens( uid, token, secret )
    where( oauth_hash: oauth_hash( uid, token, secret ) )
  end
  
  protected
  
  def build_oauth_hash
    self.oauth_hash = Authorization.oauth_hash( self.uid, self.token, self.secret )
  end

end