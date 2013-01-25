class Twilio::InboundCallsController < ApplicationController

  respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /account_plans
  # POST /account_plans.json
  def create
    # Find the phone number
    phone_number = PhoneNumber.find_by_number( params[:phone_number] )

    # Respond with an appropriate action
    respond_with Twilio::TwiML::Response.new do |r|
      # If no number found or phone number is configured to reject, ignore
      if phone_number.nil? or phone_number.should_reject_unsolicited_call?
        r.Reject reason: 'rejected'
      
      # Play a busy message
      elsif phone_number.should_play_busy_for_unsolicited_call?
        r.Reject reason: 'busy'
      
      # Play a message
      elsif phone_number.should_reply_to_unsolicited_call?
        r.Say phone_number.unsolicited_message, voice: phone_number.unsolicited_voice, language: phone_number.unsolicited_language
        r.Hangup
      
      # Always include a 'reject' by default
      else
        r.Reject
      end
    end
  end

end
