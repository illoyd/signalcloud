require 'spec_helper'
describe Twilio::InboundCallsController do
  let(:account) { create(:test_account, :test_twilio) }

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
    let(:phone_number) { create( :phone_number, account: account ) }
    let(:inbound_post_params) { build_post_params( 'To' => phone_number.number ) }

    context 'when not passing HTTP DIGEST' do
      it 'responds with unauthorised' do
        post :create, inbound_post_params
        response.status.should eq( 401 ) # Auth required
      end
    end
    
    context 'when passing HTTP DIGEST' do
      context 'when not passing message auth header' do
        it 'responds with forbidden' do
          authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
          post :create, inbound_post_params
          response.status.should eq( 403 ) # Forbidden (bad user/pass)
        end
      end

      context 'when passing message auth header' do
        it 'responds with success' do
          authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
          inject_twilio_signature( twilio_inbound_call_url, account, inbound_post_params )
          post :create, inbound_post_params
          response.status.should eq( 200 ) # OK
        end
      end
    end
    
    context 'when responding to inbound call' do
      before {
        authenticate_with_http_digest account.account_sid, account.auth_token, DIGEST_REALM
      }

      context 'when configured to reject' do
        let(:phone_number) { create( :phone_number, :reject_unsolicited_call, account: account ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( twilio_inbound_call_url, account, params ) }

        it 'responds with REJECT verb' do
          post :create, params
          response.body.should include( 'Reject' )
        end
        it 'responds with busy option' do
          post :create, params
          response.body.should include( 'rejected' )
        end
        it 'responds with xml' do
          post :create, params
          response.should have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.twilio_call_sid.should_not be_nil
        end
        it 'records call contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.call_content.should_not be_nil
        end
        it 'records call received date' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.received_at.should_not be_nil
        end
        it 'records busy-tone action' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken.should == PhoneNumber::REJECT
        end
        it 'does not record action contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_content.should be_nil
        end
        it 'does not record action taken at' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at.should be_nil
        end
      end

      context 'when configured to play busy tone' do
        let(:phone_number) { create( :phone_number, :busy_for_unsolicited_call, account: account ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( twilio_inbound_call_url, account, params ) }

        it 'responds with REJECT verb' do
          post :create, params
          response.body.should include( 'Reject' )
        end
        it 'responds with busy option' do
          post :create, params
          response.body.should include( 'busy' )
        end
        it 'responds with xml' do
          post :create, params
          response.should have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.twilio_call_sid.should_not be_nil
        end
        it 'records call contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.call_content.should_not be_nil
        end
        it 'records call received date' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.received_at.should_not be_nil
        end
        it 'records busy-tone action' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken.should == PhoneNumber::BUSY
        end
        it 'does not record action contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_content.should be_nil
        end
        it 'does not record action taken at' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at.should be_nil
        end
      end

      context 'when configured to respond with message' do
        let(:phone_number) { create( :phone_number, :reply_to_unsolicited_call, account: account ) }
        let(:params) { build_post_params( 'To' => phone_number.number ) }
        before(:each) { inject_twilio_signature( twilio_inbound_call_url, account, params ) }

        it 'responds with SAY verb' do
          post :create, params
          response.body.should include( 'Say' )
        end
        it 'responds with HANGUP verb' do
          post :create, params
          response.body.should include( 'Hangup' )
        end
        it 'responds with language option' do
          post :create, params
          response.body.should include( phone_number.unsolicited_call_language )
        end
        it 'responds with voice option' do
          post :create, params
          response.body.should include( phone_number.unsolicited_call_voice )
        end
        it 'responds with message' do
          post :create, params
          response.body.should include( phone_number.unsolicited_call_message )
        end
        it 'responds with xml' do
          post :create, params
          response.should have_content_type('application/xml')
        end
        it 'records the unsolicited call' do
          expect { post :create, params }.to change{phone_number.unsolicited_calls.count}.by(1)
        end
        it 'records call sid' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.twilio_call_sid.should_not be_nil
        end
        it 'records call contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.call_content.should_not be_nil
        end
        it 'records call received date' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.received_at.should_not be_nil
        end
        it 'records reply action' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken.should == PhoneNumber::REPLY
        end
        it 'records action contents' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_content.should_not be_nil
        end
        it 'records action taken at' do
          post :create, params
          phone_number.unsolicited_calls(true).order('created_at').last.action_taken_at.should_not be_nil
        end
      end

    end
  end
end
