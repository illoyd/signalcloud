require 'spec_helper'
describe Twilio::InboundCallsController do
  render_views
  fixtures :accounts, :phone_numbers
  let(:account) { accounts(:test_account) }
  let(:phone_number) { phone_numbers(:test_us) }
  let(:inbound_post_params) { { phone_number: phone_number.number } } 

  def build_twilio_signature( post_params )
    signature = account.twilio_validator.build_signature_for( twilio_inbound_call_url, post_params )
    return signature
  end
  
  def inject_twilio_signature( post_params )
    request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( post_params )
    #request.env['ACCEPT'] = 'xml'
  end
  
  def build_post_params( phone_number_sym=nil, params={} )
    params = inbound_post_params if params.nil?
    params[:phone_number] = phone_numbers(phone_number_sym.to_sym).number unless phone_number_sym.nil?
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
          #authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
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
      }
      let(:reject_params) { build_post_params(:reject_phone_number) }
      let(:busy_params) { build_post_params(:busy_phone_number) }
      let(:message_params) { build_post_params(:message_phone_number) }
      it 'responds with REJECT verb' do
        inject_twilio_signature( reject_params )
        post :create, reject_params
        response.body.should include( 'Reject' )
        response.body.should include( 'rejected' )
      end
      it 'responds with BUSY verb' do
        inject_twilio_signature( busy_params )
        post :create, busy_params
        response.body.should include( 'Reject' )
        response.body.should include( 'busy' )
      end
      it 'responds with SAY verb' do
        inject_twilio_signature( message_params )
        post :create, message_params
        response.body.should include( 'Say' )
        response.body.should include( 'Hangup' )
      end
    end
  end
end

# additional
#.to render_template( *args )
#.to redirecto_to( destination )

# may also use
# render_views
