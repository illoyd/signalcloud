class Authorization < ActiveRecord::Base
  belongs_to :user, inverse_of: :authorizations

  attr_encrypted :username,      key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :uid,           key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :token,         key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :secret,        key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :refresh_token, key: ATTR_ENCRYPTED_SECRET

  before_save :build_oauth_hash
  after_create :fetch_details

  def fetch_details
  end
  
  def self.provider_class( provider )
    case provider
      when 'google_oauth2', 'google', :google_oauth2, :google; GoogleAuthorization
      else; self
    end
  end

  def self.for_provider( provider, auth )
    logger.warn "Getting authorisation for #{provider} with auth: #{auth}"
    
    authorization = provider_class(provider).find_by_oauth_tokens( auth.uid, auth.credentials.token, auth.credentials.secret ).order('updated_at desc').first
    authorization = provider_class(provider).new( uid: auth.uid, token: auth.credentials.token, secret: auth.credentials.secret ) unless authorization
    authorization
  end
  
  def self.oauth_hash( uid, token, secret )
    Digest::SHA1.hexdigest("#{uid}:#{token}:#{secret}")
  end
  
  def self.find_by_oauth_tokens( uid, token, secret )
    where( oauth_hash: oauth_hash( uid, token, secret ) )
  end
  
  def expired?
    self.expires_at.past?
  end
  
protected
  
  def build_oauth_hash
    self.oauth_hash = Authorization.oauth_hash( self.uid, self.token, self.secret )
  end

end