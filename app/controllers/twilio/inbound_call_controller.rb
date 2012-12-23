class Twilio::InboundCallController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /account_plans
  # POST /account_plans.json
  def create
    # For now, just ignore
    respond_with Twilio::TwiML::Response.new
  end

end
