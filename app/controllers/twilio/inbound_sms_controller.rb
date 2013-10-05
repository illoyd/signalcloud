class Twilio::InboundSmsController < Twilio::TwilioController

  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # Create a new Inbound Message job to process the input at a later date.
    # This processing can take a while, especially when working with the database.
    # We want to close this connection as quickly as possible, however, to keep the performance up.
    InboundMessageJob.perform_async params
  
    # Terminate the connection politely, as Twilio expects.
    render :xml => Twilio::TwiML::Response.new #, :status => :created
  end

end
