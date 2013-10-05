class WebhookClient
  include HTTParty
  follow_redirects true
  maintain_method_across_redirects true
  
  attr_accessor :webhook_uri
  
  def initialize( uri )
    self.webhook_uri = uri
  end
  
  def deliver( obj )
    body = if obj.respond_to? :active_model_serializer
        obj.active_model_serializer.new(obj, {scope: obj}).to_json
      else
        obj.to_s
      end
    
    begin
      unless self.class.post( self.webhook_uri, body: body )
        raise RuntimeError.new( 'Could not deliver webhook data.' )
      end
    end
  end
end
