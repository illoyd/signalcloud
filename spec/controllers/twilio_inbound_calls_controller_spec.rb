require 'spec_helper'
describe Twilio::InboundCallsController do
  fixtures :accounts, :phone_numbers
  let(:account) { accounts(:test_account) }
  let(:phone_number) { phone_numbers(:test_us) }
  let(:inbound_post_params) { { phone_number: phone_number.number } } 

  def build_twilio_signature( post_params )
    signature = account.twilio_validator.build_signature_for( twilio_inbound_sms_url, post_params )
    return signature
  end
  
  def inject_twilio_signature( post_params )
    request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( inbound_post_params )
  end
  
  def build_post_params( phone_number_sym=nil, params=nil )
    params = inbound_post_params if params.nil?
    params[:phone_number] = phone_numbers(phone_number_sym.to_sym).phone_number if phone_number_sym.nil?
    params
  end

  describe 'POST create' do
    context 'when not passing HTTP DIGEST' do
      it 'responds with unauthorised' do
        post :create, inbound_post_params
        response.status.should eq( 401 )
      end
    end
    
    context 'when passing HTTP DIGEST' do
      context 'when not passing message auth header' do
        it 'responds with forbidden' do
          authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
          post :create, inbound_post_params
          response.status.should eq( 403 )
        end
      end

      context 'when passing message auth header' do
        it 'responds with success' do
          authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
          inject_twilio_signature( inbound_post_params )
          post :create, inbound_post_params
          response.status.should eq( 200 )
        end
      end
    end
    
    context 'when responding to inbound call' do
      before {
        authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
        inject_twilio_signature( inbound_post_params )
      }
      it 'responds with REJECT verb' do
        post :create, build_post_params(:reject_phone_number)
        response.body.should match( /Reject/ )
        response.body.should match( /rejected/ )
      end
      it 'responds with BUSY verb' do
        post :create, build_post_params(:busy_phone_number)
        response.body.should match( /Reject/ )
        response.body.should match( /busy/ )
      end
      it 'responds with SAY verb' do
        post :create, build_post_params(:message_phone_number)
        response.body.should match( /Say/ )
        response.body.should match( /Hangup/ )
      end
    end
  end
end

# additional
#.to render_template( *args )
#.to redirecto_to( destination )

# may also use
# render_views
