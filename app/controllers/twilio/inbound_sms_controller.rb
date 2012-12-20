class Twilio::InboundSmsController < ApplicationController

  respond_to :xml
  before_filter :authenticate
  
  def authenticate
    @account = self.authenticate_twilio!
  end
  
  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def show
    # For now, just ignore
    respond_with Twilio::TwiML::Response.new
  end

  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # For now, just ignore
    respond_with Twilio::TwiML::Response.new
  end

end
