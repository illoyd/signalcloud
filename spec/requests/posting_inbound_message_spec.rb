require 'spec_helper'

describe "Inbound Message for Open Conversation" do
  def build_twilio_signature( post_params )
    account.twilio_validator.build_signature_for( twilio_inbound_sms_url, post_params )
  end
  
  def inject_twilio_signature( post_params )
    request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( post_params )
  end
  
  let(:account) { create(:test_account, :master_twilio) }
  let(:to_phone_number) { build( :phone_number ) }
  let(:from_phone_number) { build( :phone_number ) }
  let(:inbound_post_params) { {
      To: to_phone_number.number,
      From: from_phone_number.number,
      SmsSid: 'SM'+SecureRandom.hex(16),
      AccountSid: account.twilio_account_sid,
      Body: 'Hello!'
    } }

  describe "POST /twilio/inbound_sms" do
    it 'raises forbidden' 
#     do
#       # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
#       get apis_path
#       response.status.should be(200)
#     end
  end

end
