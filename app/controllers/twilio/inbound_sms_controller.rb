class Twilio::InboundSmsController < ApplicationController

  before_filter :authenticate_twilio!
  respond_to :xml

  # POST /account_plans
  # POST /account_plans.json
  def index
    # For now, just ignore
    respond_with Twilio::TwiML::Response.new
  end

end
