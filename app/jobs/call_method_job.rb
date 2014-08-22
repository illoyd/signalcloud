class CallMethodJob < ActiveJob::Base
  queue_as :default
 
  def perform(object, method)
    object.send(method)
  end

end