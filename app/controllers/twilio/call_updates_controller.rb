class Twilio::CallUpdatesController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /twilio/sms_updates
  # POST /twilio/sms_updates.xml
  def create
    # Build a new update message job using the passed parameters
    Delayed::Job.enqueue UpdateCallStatusJob.new( params )
    
    # Return a blank response
    render :xml => Twilio::TwiML::Response.new
  end

end
