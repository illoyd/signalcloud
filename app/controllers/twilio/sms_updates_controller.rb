class Twilio::SmsUpdatesController < Twilio::TwilioController

  # POST /twilio/sms_updates
  # POST /twilio/sms_updates.xml
  def create
    # Build a new update message job using the passed parameters
    sms = Twilio::MessageStatus.new( params )
    UpdateMessageStatusJob.perform_async sms.sid, sms.status, nil
    
    # Return a blank response
    render :xml => Twilio::TwiML::Response.new
  end

end
