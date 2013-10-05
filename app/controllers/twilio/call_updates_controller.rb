class Twilio::CallUpdatesController < Twilio::TwilioController

  # POST /twilio/sms_updates
  # POST /twilio/sms_updates.xml
  def create
    # Build a new update message job using the passed parameters
    UpdateCallStatusJob.perform_async params
    
    # Return a blank response
    render :xml => Twilio::TwiML::Response.new
  end

end
