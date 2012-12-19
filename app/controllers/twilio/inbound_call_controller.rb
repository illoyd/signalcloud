class Twilio::InboundCallController < ApplicationController

  respond_to :xml
  before_filter :authenticate
  
  def authenticate
    @account = self.authenticate_twilio!
  end

  # POST /account_plans
  # POST /account_plans.json
  def create
    # For now, just ignore
    respond_with Twilio::TwiML::Response.new
  end

end
