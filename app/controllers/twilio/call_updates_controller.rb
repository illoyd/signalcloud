class Twilio::CallUpdatesController < ApplicationController

  respond_to :xml
  before_filter :authenticate_organization!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  
  # POST /twilio/sms_updates
  # POST /twilio/sms_updates.xml
  def create
    # Build a new update message job using the passed parameters
    Delayed::Job.enqueue UpdateCallStatusJob.new( params )
    
    # Return a blank response
    render :xml => Twilio::TwiML::Response.new
  end

end
