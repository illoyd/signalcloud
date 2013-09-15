require 'spec_helper'

describe TwilioCommunicationGateway, :vcr do
  
  let(:organization) { build :organization, :with_sid_and_token }

  context 'when new' do
    subject { build :twilio_communication_gateway }
    
    its(:new?)   { should be_true  }
    its(:ready?) { should be_false }

    describe '#create_remote!' do
      subject { build :twilio_communication_gateway, organization: organization }
      it 'does not throw an error' do
        expect{ subject.create_remote! }.not_to raise_error
      end
      it 'updates remote sid' do
        expect{ subject.create_remote! }.to change(subject, :remote_sid).from(nil)
      end
      it 'updates remote token' do
        expect{ subject.create_remote! }.to change(subject, :remote_token).from(nil)
      end
      it 'updates remote application' do
        expect{ subject.create_remote! }.to change(subject, :remote_application).from(nil)
      end
      it 'updates updated remote at' do
        expect{ subject.create_remote! }.to change(subject, :updated_remote_at).from(nil)
      end
      it 'transitions from new to ready' do
        expect { subject.create_remote! }.to change(subject, :workflow_state).to('ready')
      end
    end

    describe '#update_remote!' do
      it 'throws an error' do
        expect{ subject.update_remote! }.to raise_error
      end
    end

    describe '#twilio_client' do
      subject { build :twilio_communication_gateway }
      it 'throws error when SID and Token are missing' do
        expect{ subject.twilio_client }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
      it 'throws error when SID is missing' do
        subject.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
        expect{ subject.twilio_client }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
      it 'throws error when Token is missing' do
        subject.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
        expect{ subject.twilio_client }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

    describe '#twilio_account' do
      it 'throws error' do
        expect{ subject.twilio_account }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

    describe '#twilio_validator' do
      it 'throws error' do
        expect{ subject.twilio_validator }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end
    
    describe '#has_twilio_account?' do
      its(:'has_twilio_account?') { should be_false }
    end

    describe '#has_twilio_application?' do
      its(:'has_twilio_application?') { should be_false }
    end

    describe '#twilio_*_url' do
      it 'fails on voice url' do
        expect{ subject.twilio_voice_url }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
      it 'fails on voice status url' do
        expect{ subject.twilio_voice_status_url }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
      it 'fails on sms url' do
        expect{ subject.twilio_sms_url }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
      it 'fails on sms status url' do
        expect{ subject.twilio_sms_status_url }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

  end # Context when new
  
  context 'when ready' do
    subject { build :twilio_communication_gateway, :test, organization: organization }

    its(:new?)   { should be_false }
    its(:ready?) { should be_true  }

    describe '#create_remote!' do
      it 'throws an error' do
        expect{ subject.create_remote! }.to raise_error
      end
    end

    describe '#update_remote!' do
      subject { create :twilio_communication_gateway, :master, organization: organization }
      it 'does not throw an error' do
        expect{ subject.update_remote! }.not_to raise_error
      end
      it 'updates remote sid' do
        expect{ subject.update_remote! }.not_to change(subject, :remote_sid)
      end
      it 'updates remote token' do
        expect{ subject.update_remote! }.not_to change(subject, :remote_token)
      end
      it 'updates remote application' do
        expect{ subject.update_remote! }.not_to change(subject, :remote_application)
      end
      it 'updates updated remote at' do
        expect{ subject.update_remote! }.to change(subject, :updated_remote_at)
      end
      it 'does not transition to a new state' do
        expect { subject.update_remote! }.not_to change(subject, :ready?).from(true)
      end
    end

    describe '#twilio_client' do
      it 'returns instance of twilio client' do
        expect { subject.twilio_client }.to_not raise_error
      end
      it 'returns instance of twilio client with expected SID' do
        subject.twilio_client.account_sid.should == ENV['TWILIO_TEST_ACCOUNT_SID']
      end
    end

    describe '#twilio_account' do
      it 'returns instance of twilio organization' do
        expect{ subject.twilio_account }.to_not raise_error
      end
    end

    describe '#twilio_validator' do
      it 'returns instance of twilio validator' do
        expect{ subject.twilio_validator }.to_not raise_error
      end
    end

    describe '#has_twilio_account?' do
      its(:'has_twilio_account?') { should be_true }
    end

    describe '#has_twilio_application?' do
      its(:'has_twilio_application?') { should be_true }
    end

    describe '#twilio_*_url' do
      let(:digest_auth)             { "https://#{organization.sid}:#{organization.auth_token}" }
      its(:twilio_voice_url)        { should start_with(digest_auth) }
      its(:twilio_voice_status_url) { should start_with(digest_auth) }
      its(:twilio_sms_url)          { should start_with(digest_auth) }
      its(:twilio_sms_status_url)   { should start_with(digest_auth) }
    end

    describe '#send_sms!', :vcr do
      let(:to_number)    { Twilio::VALID_NUMBER }
      let(:from_number)  { Twilio::VALID_NUMBER }
      let(:body)         { 'Hello, world!' }
      
      context 'when requesting default response' do
        it 'returns a RESTful resource' do
          subject.send_sms!( to_number, from_number, body ).should be_a Twilio::REST::InstanceResource
        end
      end
      
      context 'when requesting raw response' do
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :raw ) }

        it 'returns a RESTful resource' do
          query.should be_a Twilio::REST::InstanceResource
        end
        it 'returns the TO' do
          query.to.should == to_number
        end
        it 'returns the FROM' do
          query.from.should == from_number
        end
        it 'returns the BODY' do
          query.body.should == body
        end

        it 'errors with #[:to]' do
          expect { query[:to] }.to raise_error
        end
        it 'errors with #[:from]' do
          expect { query[:from] }.to raise_error
        end
        it 'errors with #[:body]' do
          expect { query[:body] }.to raise_error
        end
      end
      
      context 'when requesting with callback'  do
        let(:query) { subject.send_sms!( to_number, from_number, body, default_callback: true ) }

        it 'returns a RESTful resource' do
          query.should be_a Twilio::REST::InstanceResource
        end
        it 'returns the TO' do
          query.to.should == to_number
        end
        it 'returns the FROM' do
          query.from.should == from_number
        end
        it 'returns the BODY' do
          query.body.should == body
        end
      end
      
      context 'when requesting hash response' do
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :hash ) }

        it 'returns a Hash resource' do
          query.should be_a Hash
        end
        it 'returns the :TO' do
          query[:to].should == to_number
        end
        it 'returns the :FROM' do
          query[:from].should == from_number
        end
        it 'returns the :BODY' do
          query[:body].should == body
        end
        it 'returns the string TO' do
          query['to'].should == to_number
        end
        it 'returns the string FROM' do
          query['from'].should == from_number
        end
        it 'returns the string BODY' do
          query['body'].should == body
        end
        it 'errors with #to' do
          expect { query.to }.to raise_error
        end
        it 'errors with #from' do
          expect { query.from }.to raise_error
        end
        it 'errors with #body' do
          expect { query.body }.to raise_error
        end
      end
      
      context 'when requesting smash response' do
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :smash ) }

        it 'returns a Hash resource' do
          query.should be_a APISmith::Smash
        end
        it 'returns the TO' do
          query.to.should == to_number
        end
        it 'returns the FROM' do
          query.from.should == from_number
        end
        it 'returns the BODY' do
          query.body.should == body
        end
        it 'returns the :TO' do
          query[:to].should == to_number
        end
        it 'returns the :FROM' do
          query[:from].should == from_number
        end
        it 'returns the :BODY' do
          query[:body].should == body
        end
  
        it 'returns the customer number' do
          query.customer_number.should == to_number
        end
        it 'returns the internal number' do
          query.internal_number.should == from_number
        end
        
        it 'returns the date created' do
          query.date_created.should_not be_nil
        end
        it 'returns the created at' do
          query.created_at.should_not be_nil
        end
      end
    end

  end

  describe '#assemble_twilio_account_data' do

    context 'when attached to organization' do
      subject { build :twilio_communication_gateway, :test, organization: organization }

      it 'returns a hash' do
        subject.send(:assemble_twilio_account_data).should be_a Hash
      end
      
      it 'includes all expected keys' do
        subject.send(:assemble_twilio_account_data).should include( 'FriendlyName' )
      end

    end

    context 'when organization is not attached' do
      subject { build :twilio_communication_gateway, :test }
      it 'raises error' do
        expect{ subject.send(:assemble_twilio_account_data) }.not_to raise_error
      end
    end

  end

  describe '#assemble_twilio_application_data' do

    context 'when attached to organization' do
      subject { build :twilio_communication_gateway, :test, organization: organization }
      let(:digest_auth) { "https://#{organization.sid}:#{organization.auth_token}" }

      it 'returns a hash' do
        subject.send(:assemble_twilio_application_data).should be_a Hash
      end

      [ 'VoiceUrl', 'VoiceFallbackUrl', 'StatusCallback', 'SmsUrl', 'SmsFallbackUrl', 'SmsStatusCallback' ].each do |key|
        it "includes #{key}" do
          subject.send(:assemble_twilio_application_data).should include(key)
        end
        it "embeds auth tokens in #{key}" do
          subject.send(:assemble_twilio_application_data)[key].should start_with(digest_auth)
        end
      end
      
      [ 'VoiceMethod', 'VoiceFallbackMethod', 'StatusCallbackMethod', 'SmsMethod', 'SmsFallbackMethod' ].each do |key|
        it "includes #{key}" do
          subject.send(:assemble_twilio_application_data).should include(key)
        end
        it "uses POST for #{key}" do
          subject.send(:assemble_twilio_application_data)[key].should == 'POST'
        end
      end

    end

    context 'when organization is not attached' do
      subject { build :twilio_communication_gateway, :test }
      it 'raises error' do
        expect{ subject.send(:assemble_twilio_application_data) }.not_to raise_error
      end
    end

  end # Context when ready









#   describe '#create_twilio_account' do
#     context 'when organization already created' do
#       subject { create :organization, :test_twilio, :with_sid_and_token }
#       it 'does not raise error' do
#         expect{ subject.communication_gateway.create_twilio_account }.to_not raise_error
#       end
#       it 'does not change #twilio_account_sid' do
#         expect { subject.communication_gateway.create_twilio_account }.to_not change(subject, :twilio_account_sid)
#       end
#       it 'does not change #twilio_auth_token' do
#         expect { subject.communication_gateway.create_twilio_account }.to_not change(subject, :twilio_auth_token)
#       end
#     end
#   end
#   
#   describe '#create_twilio_account!' do
# 
#     context 'when organization not already created' do
#       subject { create :organization, :with_sid_and_token }
#       it 'does not raise error' do
#         expect{ subject.communication_gateway.create_twilio_account! }.to_not raise_error
#       end
#       it 'adds .twilio_account_sid' do
#         expect { subject.communication_gateway.create_twilio_account! }.to change(subject, :twilio_account_sid).from(nil)
#       end
#       it 'adds .twilio_auth_token' do
#         expect { subject.communication_gateway.create_twilio_account! }.to change(subject, :twilio_auth_token).from(nil)
#       end
#       it 'allows creating a twilio client' do
#         expect{ subject.twilio_client }.to raise_error(SignalCloud::MissingTwilioAccountError)
#         subject.create_twilio_account!
#         expect{ subject.twilio_client }.to_not raise_error
#       end
#     end
# 
#     context 'when organization already created' do
#       subject { create :organization, :test_twilio, :with_sid_and_token }
#       it 'raises error' do
#         expect{ subject.communication_gateway.create_twilio_account! }.to raise_error(SignalCloud::TwilioAccountAlreadyExistsError)
#       end
#       it 'does not change .twilio_account_sid' do
#         expect { subject.communication_gateway.create_twilio_account! rescue nil }.to_not change(subject, :twilio_account_sid)
#       end
#       it 'does not change .twilio_auth_token' do
#         expect { subject.communication_gateway.create_twilio_account! rescue nil }.to_not change(subject, :twilio_auth_token)
#       end
#     end
# 
#   end
#   
#   describe '#create_or_update_twilio_application' do
#   
#     context 'when organization is not configured' do
#       let(:organization)   { create :organization, :with_sid_and_token }
#       it 'raises error' do
#         expect { organization.communication_gateway.create_or_update_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
#       end
#     end
#     
#     context 'when application is not configured, creates' do
#       let(:organization)   { create :organization, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
#       it 'does not raise error' do
#         expect { organization.communication_gateway.create_or_update_twilio_application }.to_not raise_error()
#       end
#       it 'returns a response' do
#         organization.communication_gateway.create_or_update_twilio_application.should_not be_nil
#       end
#       it 'updates twilio application' do
#         expect { organization.communication_gateway.create_or_update_twilio_application }.to change{ organization.twilio_application_sid }.from(nil)
#       end
#     end
#     
#     context 'when application is configured, updates' do
#       let(:organization)   { create :organization, :master_twilio, :with_sid_and_token }
#       it 'does not raise error' do
#         expect { organization.communication_gateway.create_or_update_twilio_application }.to_not raise_error()
#       end
#       it 'returns a response' do
#         organization.communication_gateway.create_or_update_twilio_application.should_not be_nil
#       end
#       it 'does not change twilio application' do
#         expect { organization.communication_gateway.create_or_update_twilio_application }.not_to change{ organization.twilio_application_sid }
#       end
#     end
#     
#   end
#   
#   describe '#create_twilio_application' do
#     
#     context 'when organization is configured' do
#       context 'and when application is configured' do
#         subject { create :organization, :master_twilio, :with_sid_and_token }
#         it 'does not raise error' do
#           expect { subject.create_twilio_application }.not_to raise_error
#         end
#         it 'does not change twilio_application_sid' do
#           expect { subject.create_twilio_application }.not_to change(subject, :twilio_application_sid)
#         end
#         it 'returns nil (since nothing was created)' do
#           subject.create_twilio_application.should be_nil
#         end
#       end
# 
#       context 'and when application is not configured' do
#         subject { create :organization, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
#         it 'does not raise error' do
#           expect { subject.create_twilio_application }.not_to raise_error
#         end
#         it 'returns a response object' do
#           subject.create_twilio_application.should_not be_nil
#         end
#         it 'sets twilio_application_sid' do
#           expect { subject.create_twilio_application }.to change(subject, :twilio_application_sid).from(nil)
#         end
#       end
#     end
#     
#     context 'when organization is not configured' do
#       subject { create :organization }
#       it 'raises error' do
#         expect{ subject.create_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
#       end
#     end
# 
#   end
#   
#   describe '#create_twilio_application!' do
#     context 'when accout and application are configured' do
#       subject { create :organization, :master_twilio, :with_sid_and_token }
#       it 'raises application-exists error' do
#         expect { subject.create_twilio_application! }.to raise_error(SignalCloud::TwilioApplicationAlreadyExistsError)
#       end
#     end
#   end
#   
#   describe '#update_twilio_application' do
#     
#     context 'when organization is configured' do
#       context 'and when application is configured' do
#         subject { create :organization, :master_twilio, :with_sid_and_token }
#         it 'does not raise error' do
#           expect { subject.update_twilio_application }.not_to raise_error
#         end
#         it 'does not change twilio_application_sid' do
#           expect { subject.update_twilio_application }.not_to change(subject, :twilio_application_sid)
#         end
#         it 'returns response' do
#           subject.update_twilio_application.should_not be_nil
#         end
#       end
# 
#       context 'and when application is not configured' do
#         subject { create :organization, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
#         it 'does not raise error' do
#           expect { subject.update_twilio_application }.not_to raise_error
#         end
#         it 'does not change twilio_application_sid' do
#           expect { subject.update_twilio_application }.not_to change(subject, :twilio_application_sid).from(nil)
#         end
#         it 'returns nil (nothing updated)' do
#           subject.update_twilio_application.should be_nil
#         end
#       end
#     end
#     
#     context 'when organization is not configured' do
#       subject { create :organization }
#       it 'raises error' do
#         expect{ subject.create_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
#       end
#     end
# 
#   end
#   
#   
#   describe '#twilio_application_configuration' do
# 
#     context 'when organization is configured' do
#       subject { create :organization, :test_twilio }
#       let(:digest_auth) { "https://#{subject.sid}:#{subject.auth_token}" }
#       its(:twilio_application_configuration) { should be_a Hash }
# 
#       [ 'VoiceUrl', 'VoiceFallbackUrl', 'StatusCallback', 'SmsUrl', 'SmsFallbackUrl', 'SmsStatusCallback' ].each do |key|
#         its(:'twilio_application_configuration.keys') { should include(key) }
#         it "embedds auth tokens in #{key}" do
#           subject.twilio_application_configuration[key].should start_with(digest_auth)
#         end
#       end
#       
#       [ 'VoiceMethod', 'VoiceFallbackMethod', 'StatusCallbackMethod', 'SmsMethod', 'SmsFallbackMethod' ].each do |key|
#         its(:'twilio_application_configuration.keys') { should include(key) }
#         it "uses POST for #{key}" do
#           subject.twilio_application_configuration[key].should == 'POST'
#         end
#       end
# 
#     end
# 
#     context 'when organization is not configured' do
#       subject { create :organization }
#       it 'raises error' do
#         expect{ subject.twilio_application_configuration }.to raise_error(SignalCloud::MissingTwilioAccountError)
#       end
#     end
# 
#   end
  
#   describe '#send_sms!', :vcr do
#     let(:organization) { create :organization, :test_twilio, :with_sid_and_token }
#     let(:to_number)    { Twilio::VALID_NUMBER }
#     let(:from_number)  { Twilio::VALID_NUMBER }
#     let(:body)         { 'Hello, world!' }
#     
#     context 'when requesting default response' do
#       subject { organization.send_sms!( to_number, from_number, body ) }
#       it { should be_a Twilio::REST::InstanceResource }
#     end
#     
#     context 'when requesting raw response' do
#       subject { organization.send_sms!( to_number, from_number, body, response_format: :raw ) }
#       it { should be_a Twilio::REST::InstanceResource }
#       its(:to)   { should == to_number }
#       its(:from) { should == from_number }
#       its(:body) { should == body }
#       it 'errors with #[:to]' do
#         expect {subject[:to] }.to raise_error
#       end
#       it 'errors with #[:from]' do
#         expect {subject[:from] }.to raise_error
#       end
#       it 'errors with #[:body]' do
#         expect {subject[:body] }.to raise_error
#       end
#     end
#     
#     context 'when requesting with callback'  do
#       subject { organization.send_sms!( to_number, from_number, body, default_callback: true ) }
#       it { should be_a Twilio::REST::InstanceResource }
#       its(:to)     { should == to_number }
#       its(:from)   { should == from_number }
#       its(:body)   { should == body }
#     end
#     
#     context 'when requesting hash response' do
#       subject { organization.send_sms!( to_number, from_number, body, response_format: :hash ) }
#       it { should be_a Hash }
#       its([:to])   { should == to_number }
#       its([:from]) { should == from_number }
#       its([:body]) { should == body }
#       its(['to'])   { should == to_number }
#       its(['from']) { should == from_number }
#       its(['body']) { should == body }
#       it 'errors with #to' do
#         expect {subject.to }.to raise_error
#       end
#       it 'errors with #from' do
#         expect {subject.from }.to raise_error
#       end
#       it 'errors with #body' do
#         expect {subject.body }.to raise_error
#       end
#     end
#     
#     context 'when requesting smash response' do
#       subject { organization.send_sms!( to_number, from_number, body, response_format: :smash ) }
#       it { should be_a APISmith::Smash }
#       its(:to)     { should == to_number }
#       its(:from)   { should == from_number }
#       its(:body)   { should == body }
#       its([:to])   { should == to_number }
#       its([:from]) { should == from_number }
#       its([:body]) { should == body }
# 
#       its(:customer_number)  { should == to_number }
#       its(:internal_number)  { should == from_number }
#       
#       its(:date_created) { should be_a Time }
#       its(:created_at)   { should be_a Time }
#     end
#   end

end
