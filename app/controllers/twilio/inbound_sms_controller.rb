class Twilio::InboundSmsController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # For now, just ignore
    render :xml => Twilio::TwiML::Response.new, :status => :created
  end

end
