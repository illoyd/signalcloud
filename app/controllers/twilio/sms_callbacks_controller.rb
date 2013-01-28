class Twilio::SmsCallbacksController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # Build a new update message job using the passed parameters
    Delayed::Job.enqueue UpdateMessageJob.new( params )
    
    # Return a blank response
    render :xml => Twilio::TwiML::Response.new
  end

end
