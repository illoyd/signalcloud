class WebhookClient
  include HTTParty
  follow_redirects true
  maintain_method_across_redirects true
  
  attr_accessor :webhook_uri
  
  def initialize( uri )
    self.webhook_uri = uri
  end
  
  def deliver( obj )
    body = obj.as_json
    self.class.post( self.webhook_uri, body: body )
  end
end
