require 'spec_helper'
describe Twilio::SmsUpdatesController do
  #render_views
  let(:organization)       { create :test_organization, :with_sid_and_token }
  let(:comm_gateway)       { organization.communication_gateway_for(:twilio) }
  let(:to_phone_number)    { build :phone_number, organization: organization, communication_gateway: comm_gateway }
  let(:from_phone_number)  { build :phone_number, organization: organization, communication_gateway: comm_gateway }
  let(:update_post_params) { {
      To: to_phone_number.number,
      From: from_phone_number.number,
      SmsSid: 'SM'+SecureRandom.hex(16),
      AccountSid: organization.communication_gateway_for(:twilio).remote_sid,
      Body: 'Hello!',
      SmsStatus: 'sent'
    } }

  describe 'POST create' do
    context 'when not passing HTTP DIGEST' do
      it 'responds with unauthorised' do
        post :create, update_post_params
        response.status.should eq( 401 )
      end
    end
    
    context 'when passing HTTP DIGEST' do
      context 'when not passing message auth header' do
        it 'responds with forbidden' do
          authenticate_with_digest organization.sid, organization.auth_token, DIGEST_REALM
          post :create, update_post_params
          response.status.should eq( 403 )
        end
      end

      context 'when passing message auth header' do
        it 'responds with success' do
          authenticate_with_digest organization.sid, organization.auth_token, DIGEST_REALM
          inject_twilio_signature( twilio_sms_update_url, organization, update_post_params )
          post :create, update_post_params
          response.status.should eq( 200 )
        end
      end
    end
    
    context 'when responding to sms update' do
      before {
        authenticate_with_digest organization.sid, organization.auth_token, DIGEST_REALM
        inject_twilio_signature( twilio_sms_update_url, organization, update_post_params )
      }
      it 'responds with blank TwiML' do
        post :create, update_post_params
        response.body.should include('<Response/>')
      end
      it 'adds a job to process request' do
        expect { post :create, update_post_params }.to change(UpdateMessageStatusJob.jobs, :count).by(1)
      end
      it 'responds with xml' do
        post :create, update_post_params
        response.should have_content_type('application/xml')
      end
    end

  end

end
