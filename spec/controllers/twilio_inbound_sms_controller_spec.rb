require 'spec_helper'
describe Twilio::InboundSmsController do
  #render_views
  let(:account) { create(:test_account) }
  let(:to_phone_number) { build( :phone_number ) }
  let(:from_phone_number) { build( :phone_number ) }
  let(:inbound_post_params) { {
      To: to_phone_number.number,
      From: from_phone_number.number,
      SmsSid: 'SM'+SecureRandom.hex(16),
      AccountSid: account.twilio_account_sid,
      Body: 'Hello!'
    } }

  def build_twilio_signature( post_params )
    account.twilio_validator.build_signature_for( twilio_inbound_sms_url, post_params )
  end
  
  def inject_twilio_signature( post_params )
    request.env['HTTP_X_TWILIO_SIGNATURE'] = build_twilio_signature( post_params )
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
    
    context 'when responding to inbound sms' do
      it 'responds with blank TwiML' do
        authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
        inject_twilio_signature( inbound_post_params )
        post :create, inbound_post_params
        response.body.should include('<Response/>')
      end
      it 'adds a job to process request' do
        expect {
          authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
          inject_twilio_signature( inbound_post_params )
          post :create, inbound_post_params
        }.to change{Delayed::Job.count}.by(1)
      end
      it 'responds with xml' do
        authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
        inject_twilio_signature( inbound_post_params )
        post :create, inbound_post_params
        response.should have_content_type('application/xml')
      end
    end
  end
end
