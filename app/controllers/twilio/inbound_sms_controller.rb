class Twilio::InboundSmsController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  
  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # Create a new Inbound Message job to process the input at a later date.
    # This processing can take a while, especially when working with the database.
    # We want to close this connection as quickly as possible, however, to keep the performance up.
    Delayed::Job.enqueue InboundMessageJob.new(params)
  
    # Terminate the connection politely, as Twilio expects.
    render :xml => Twilio::TwiML::Response.new #, :status => :created
  end

end
