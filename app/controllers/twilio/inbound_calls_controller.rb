##
# Twilio Inbound Calls
#
# Handle inbound calls from Twilio. Twilio will generally provide the following parameters:
#
#   +CallSid+       A unique identifier for this call, generated by Twilio.
#   +AccountSid+	  Your Twilio account id. It is 34 characters long, and always starts with the letters AC.
#   +From+          The phone number or client identifier of the party that initiated the call. Phone numbers are formatted with a '+' and country code, e.g. +16175551212 (E.164 format). Client identifiers begin with the client: URI scheme; for example, for a call from a client named 'tommy', the From parameter will be client:tommy.
#   +To+            The phone number or client identifier of the called party. Phone numbers are formatted with a '+' and country code, e.g. +16175551212 (E.164 format). Client identifiers begin with the client: URI scheme; for example, for a call to a client named 'jenny', the To parameter will be client:jenny.
#   +CallStatus+    A descriptive status for the call. The value is one of queued, ringing, in-progress, completed, busy, failed or no-answer. See the CallStatus section below for more details.
#   +ApiVersion+    The version of the Twilio API used to handle this call. For incoming calls, this is determined by the API version set on the called number. For outgoing calls, this is the API version used by the outgoing call's REST API request.
#   +Direction+     Indicates the direction of the call. In most cases this will be inbound, but if you are using <Dial> it will be outbound-dial.
#   +ForwardedFrom+ This parameter is set only when Twilio receives a forwarded call, but its value depends on the caller's carrier including information when forwarding. Not all carriers support passing this information.
#   +CallerName+    This parameter is set when the IncomingPhoneNumber that received the call has had its VoiceCallerIdLookup value set to true ($0.01 per look up).
class Twilio::InboundCallsController < ApplicationController

  #respond_to :xml
  before_filter :authenticate_account!, :authenticate_twilio!
  skip_before_filter :authenticate_user!
  
  # POST /account_plans
  # POST /account_plans.json
  def create
    # Find the phone number
    phone_number = PhoneNumber.find_by_number( params[:To] ).first
    
    # Add record of inbound call
    unsolicited_call = phone_number.nil? ? nil : phone_number.unsolicited_calls.build( twilio_call_sid: params[:CallSid], customer_number: params[:From], received_at: DateTime.now, call_content: params )

    # Respond with an appropriate action
    twiml = Twilio::TwiML::Response.new do |r|
      # If no number found or phone number is configured to reject, ignore
      if phone_number.nil? || phone_number.should_reject_unsolicited_call?
        unsolicited_call.action_taken = PhoneNumber::REJECT if unsolicited_call
        r.Reject reason: 'rejected'
      
      # Play a busy message
      elsif phone_number.should_play_busy_for_unsolicited_call?
        unsolicited_call.action_taken = PhoneNumber::BUSY if unsolicited_call
        r.Reject reason: 'busy'
      
      # Play a message
      elsif phone_number.should_reply_to_unsolicited_call?
        if unsolicited_call
          unsolicited_call.action_taken = PhoneNumber::REPLY
          unsolicited_call.action_taken_at = DateTime.now
          unsolicited_call.action_content = { message: phone_number.unsolicited_call_message, voice: phone_number.unsolicited_call_voice, language: phone_number.unsolicited_call_language }
        end

        r.Say phone_number.unsolicited_call_message, voice: phone_number.unsolicited_call_voice, language: phone_number.unsolicited_call_language
        r.Hangup
      
      # Always include a 'reject' by default
      else
        unsolicited_call.action_taken = PhoneNumber::REJECT if unsolicited_call
        r.Reject
      end
    end
    
    # Save the unsolicited call record
    unsolicited_call.save if unsolicited_call

    # Finally, render the XML nicely
    render xml: twiml
  end
  
end
