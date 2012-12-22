class Twilio::InboundSmsController < ApplicationController

  respond_to :xml, :text
  before_filter :authenticate_account!, :authenticate_twilio!
  
  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  #def show
  #  # For now, just ignore
  #  respond_with Twilio::TwiML::Response.new
  #end

  # POST /twilio/inbound_sms
  # POST /twilio/inbound_sms.xml
  def create
    # For now, just ignore
    render :xml => Twilio::TwiML::Response.new, :status => :created
  end

end
