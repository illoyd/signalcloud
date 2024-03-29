require 'spec_helper'
describe Twilio::InboundCallsController, :type => :controller do
  let(:organization) { create(:test_organization, :with_sid_and_token) }
  let(:comm_gateway) { organization.communication_gateway_for(:twilio) }

  def build_post_params( params={} )
    { 'CallSid' => 'CA' + SecureRandom.hex(16),
      'AccountSid' => 'AC' + SecureRandom.hex(16),
      'From' => Twilio::VALID_NUMBER,
      'To' => Twilio::VALID_NUMBER,
      'CallStatus' => 'ringing',
      'ApiVersion' => '2010-04-01',
      'Direction' => 'inbound',
      'ForwardedFrom' => nil,
      'CallerName' => nil
    }.merge( params )
  end

  describe 'POST create' do
    let(:phone_number) { create( :phone_number, organization: organization, communication_gateway: comm_gateway ) }
    let(:inbound_post_params) { build_post_params( 'To' => phone_number.number ) }

    context 'when not passing HTTP DIGEST' do
      it 'responds with unauthorised' do
        post :create, inbound_post_params
        expect(response.status).to eq( 401 ) # Auth required
      end
    end
    
    context 'when passing HTTP DIGEST' do
      context 'when not passing message auth header' do
        it 'responds with forbidden' do
          authenticate_with_http_digest organization.sid, organization.auth_token, :post, :create
          post :create, inbound_post_params
          expect(response.status).to eq( 403 ) # Forbidden (bad user/pass)
        end
      end

      context 'when passing message auth header' do
        it 'responds with success' do
          authenticate_with_http_digest organization.sid, organization.auth_token, :post, :create
          inject_twilio_signature( subject.twilio_inbound_call_url, organization, inbound_post_params )
          post :create, inbound_post_params
          expect(response.status).to eq( 200 ) # OK
        end
      end
    end
    
    context 'when responding to inbound call' do
      before {
        authenticate_with_http_digest organization.sid, organization.auth_token, :post, :create
      }

      context 'when configured to reject' do
        let(:phone_number) { create( :phone_number, :reject_unsolicited_call, organization: organization, communication_gateway: comm_gateway ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( subject.twilio_inbound_call_url, organization, params ) }

        it 'responds with REJECT verb' do
          post :create, params
          expect(response.body).to include( 'Reject' )
        end
        it 'responds with busy option' do
          post :create, params
          expect(response.body).to include( 'rejected' )
        end
        it 'responds with xml' do
          post :create, params
          expect(response).to have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.provider_sid).not_to be_nil
        end
        it 'records call contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.call_content).not_to be_nil
        end
        it 'records call received date' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.received_at).not_to be_nil
        end
        it 'records busy-tone action' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken).to eq(PhoneNumber::REJECT)
        end
        it 'does not record action contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_content).to be_nil
        end
        it 'does not record action taken at' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at).to be_nil
        end
      end

      context 'when configured to play busy tone' do
        let(:phone_number) { create( :phone_number, :busy_for_unsolicited_call, organization: organization, communication_gateway: comm_gateway ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( subject.twilio_inbound_call_url, organization, params ) }

        it 'responds with REJECT verb' do
          post :create, params
          expect(response.body).to include( 'Reject' )
        end
        it 'responds with busy option' do
          post :create, params
          expect(response.body).to include( 'busy' )
        end
        it 'responds with xml' do
          post :create, params
          expect(response).to have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.provider_sid).not_to be_nil
        end
        it 'records call contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.call_content).not_to be_nil
        end
        it 'records call received date' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.received_at).not_to be_nil
        end
        it 'records busy-tone action' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken).to eq(PhoneNumber::BUSY)
        end
        it 'does not record action contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_content).to be_nil
        end
        it 'does not record action taken at' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at).to be_nil
        end
      end

      context 'when configured to respond with message' do
        let(:phone_number) { create( :phone_number, :reply_to_unsolicited_call, organization: organization, communication_gateway: comm_gateway ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( subject.twilio_inbound_call_url, organization, params ) }

        it 'responds with SAY verb' do
          post :create, params
          expect(response.body).to include( 'Say' )
        end
        it 'responds with HANGUP verb' do
          post :create, params
          expect(response.body).to include( 'Hangup' )
        end
        it 'responds with language option' do
          post :create, params
          expect(response.body).to include( phone_number.unsolicited_call_language )
        end
        it 'responds with voice option' do
          post :create, params
          expect(response.body).to include( phone_number.unsolicited_call_voice )
        end
        it 'responds with message' do
          post :create, params
          expect(response.body).to include( phone_number.unsolicited_call_message )
        end
        it 'responds with xml' do
          post :create, params
          expect(response).to have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.provider_sid).not_to be_nil
        end
        it 'records call contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.call_content).not_to be_nil
        end
        it 'records call received date' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.received_at).not_to be_nil
        end
        it 'records reply action' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken).to eq(PhoneNumber::REPLY)
        end
        it 'records action contents' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_content).not_to be_nil
        end
        it 'records action taken at' do
          post :create, params
          expect(phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at).not_to be_nil
        end
      end

    end
  end
end
