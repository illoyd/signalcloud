# encoding: UTF-8
require 'spec_helper'

shared_examples 'sends messages' do
  it 'does not error' do
    expect{ subject.send_sms!( to_number, from_number, body ) }.not_to raise_error
  end
  it 'returns a provider ID' do
    expect(subject.send_sms!( to_number, from_number, body, response_format: :smash ).sid).not_to be_nil
  end
end

describe TwilioCommunicationGateway, :vcr, :skip, :type => :model do
  
  let(:organization) { build :organization, :with_sid_and_token }

  context 'when new' do
    subject { build :twilio_communication_gateway }
    
    describe '#new?' do
      subject { super().new? }
      it { is_expected.to be_truthy  }
    end

    describe '#ready?' do
      subject { super().ready? }
      it { is_expected.to be_falsey }
    end

    describe '#create_remote!' do
      subject { create :twilio_communication_gateway, organization: organization }
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
        expect{ subject.create_remote! }.to change(subject, :workflow_state).to('ready')
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
      describe '#has_twilio_account?' do
        subject { super().has_twilio_account? }
        it { is_expected.to be_falsey }
      end
    end

    describe '#has_twilio_application?' do
      describe '#has_twilio_application?' do
        subject { super().has_twilio_application? }
        it { is_expected.to be_falsey }
      end
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
    subject { create :twilio_communication_gateway, :test, organization: organization }

    describe '#new?' do
      subject { super().new? }
      it { is_expected.to be_falsey }
    end

    describe '#ready?' do
      subject { super().ready? }
      it { is_expected.to be_truthy  }
    end

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
        expect { subject.twilio_client }.not_to raise_error
      end
      it 'returns instance of twilio client with expected SID' do
        expect(subject.twilio_client.account_sid).to eq(ENV['TWILIO_TEST_ACCOUNT_SID'])
      end
    end

    describe '#twilio_account' do
      it 'returns instance of twilio organization' do
        expect{ subject.twilio_account }.not_to raise_error
      end
    end

    describe '#twilio_validator' do
      it 'returns instance of twilio validator' do
        expect{ subject.twilio_validator }.not_to raise_error
      end
    end

    describe '#has_twilio_account?' do
      describe '#has_twilio_account?' do
        subject { super().has_twilio_account? }
        it { is_expected.to be_truthy }
      end
    end

    describe '#has_twilio_application?' do
      describe '#has_twilio_application?' do
        subject { super().has_twilio_application? }
        it { is_expected.to be_truthy }
      end
    end

    describe '#twilio_*_url' do
      let(:digest_auth)             { "https://#{organization.sid}:#{organization.auth_token}" }

      describe '#twilio_voice_url' do
        subject { super().twilio_voice_url }
        it { is_expected.to start_with(digest_auth) }
      end

      describe '#twilio_voice_status_url' do
        subject { super().twilio_voice_status_url }
        it { is_expected.to start_with(digest_auth) }
      end

      describe '#twilio_sms_url' do
        subject { super().twilio_sms_url }
        it { is_expected.to start_with(digest_auth) }
      end

      describe '#twilio_sms_status_url' do
        subject { super().twilio_sms_status_url }
        it { is_expected.to start_with(digest_auth) }
      end
    end

    describe '#send_sms!', :vcr do
      let(:to_number)    { Twilio::VALID_NUMBER }
      let(:from_number)  { '+12026013854' }
      let(:body)         { 'Hello, world!' }
      subject { build :twilio_communication_gateway, :test, organization: organization }
      
      context 'when requesting default response' do
        it 'returns a smash resource' do
          expect(subject.send_sms!( to_number, from_number, body )).to be_a APISmith::Smash
        end
      end
      
      context 'when requesting raw response' do
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :raw ) }

        it 'returns a RESTful resource' do
          expect(query).to be_a Twilio::REST::InstanceResource
        end
        it 'returns the TO' do
          expect(query.to).to eq(to_number)
        end
        it 'returns the FROM' do
          expect(query.from).to eq(from_number)
        end
        it 'returns the BODY' do
          expect(query.body).to eq(body)
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
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :raw, default_callback: true ) }

        it 'returns a RESTful resource' do
          expect(query).to be_a Twilio::REST::InstanceResource
        end
        it 'returns the TO' do
          expect(query.to).to eq(to_number)
        end
        it 'returns the FROM' do
          expect(query.from).to eq(from_number)
        end
        it 'returns the BODY' do
          expect(query.body).to eq(body)
        end
      end
      
      context 'when requesting hash response' do
        let(:query) { subject.send_sms!( to_number, from_number, body, response_format: :hash ) }

        it 'returns a Hash resource' do
          expect(query).to be_a Hash
        end
        it 'returns the :TO' do
          expect(query[:to]).to eq(to_number)
        end
        it 'returns the :FROM' do
          expect(query[:from]).to eq(from_number)
        end
        it 'returns the :BODY' do
          expect(query[:body]).to eq(body)
        end
        it 'returns the string TO' do
          expect(query['to']).to eq(to_number)
        end
        it 'returns the string FROM' do
          expect(query['from']).to eq(from_number)
        end
        it 'returns the string BODY' do
          expect(query['body']).to eq(body)
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

        it 'returns a Smash resource' do
          expect(query).to be_a APISmith::Smash
        end
        it 'returns the TO' do
          expect(query.to).to eq(to_number)
        end
        it 'returns the FROM' do
          expect(query.from).to eq(from_number)
        end
        it 'returns the BODY' do
          expect(query.body).to eq(body)
        end
        it 'returns the :TO' do
          expect(query[:to]).to eq(to_number)
        end
        it 'returns the :FROM' do
          expect(query[:from]).to eq(from_number)
        end
        it 'returns the :BODY' do
          expect(query[:body]).to eq(body)
        end
  
        it 'returns the customer number' do
          expect(query.customer_number).to eq(to_number)
        end
        it 'returns the internal number' do
          expect(query.internal_number).to eq(from_number)
        end
        
        it 'returns the created at' do
          expect(query.created_at).not_to be_nil
        end
      end
      
      context 'sends typical message' do
        let(:body) { 'confirmed' }
        include_examples 'sends messages'
      end
      
      context 'sends 160-character message' do
        let(:body) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origi' }
        include_examples 'sends messages'
      end
      
      context 'sends 1-character message' do
        let(:body) { 'M' }
        include_examples 'sends messages'
      end
      
      context 'sends 161-character message' do
        let(:body) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin' }
        include_examples 'sends messages'
      end
  
      context 'sends super long message' do
        let(:body) { 'Mumblecore messenger bag fashion axe whatever pitchfork, squid sapiente banksy cosby sweater enim vegan mcsweeney\'s carles chambray. Stumptown twee single-origin coffee next level, echo park elit quis minim sed blue bottle. Single-origin coffee leggings cliche, farm-to-table try-hard ullamco wes anderson narwhal literally hella nisi actually. Retro whatever semiotics odd future 8-bit, polaroid letterpress non consectetur seitan cosby sweater. Pariatur fanny pack proident, carles skateboard scenester voluptate. Sunt consequat jean shorts chambray bushwick, lo-fi next level dolor yr. Wayfarers swag keffiyeh, williamsburg lo-fi tonx put a bird on it tumblr keytar YOLO fashion axe pug tempor delectus.' }
        include_examples 'sends messages'
      end
  
      context 'sends UTF message' do
        let(:body) { 'こんにちは' }
        include_examples 'sends messages'
      end
      
      context 'sends 70-character UTF message' do
        let(:body) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 1234' }
        include_examples 'sends messages'
      end
      
      context 'sends 71-character UTF message' do
        let(:body) { 'こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは こんにちは 12345' }
        include_examples 'sends messages'
      end
      
      context 'sends super-long UTF message' do
        let(:body) { 'こんにちは' * 30 }
        include_examples 'sends messages'
      end
    end

  end

  describe '#assemble_twilio_account_data' do

    context 'when attached to organization' do
      subject { build :twilio_communication_gateway, :test, organization: organization }

      it 'returns a hash' do
        expect(subject.send(:assemble_twilio_account_data)).to be_a Hash
      end
      
      it 'includes all expected keys' do
        expect(subject.send(:assemble_twilio_account_data)).to include( 'FriendlyName' )
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
        expect(subject.send(:assemble_twilio_application_data)).to be_a Hash
      end

      [ 'VoiceUrl', 'VoiceFallbackUrl', 'StatusCallback', 'SmsUrl', 'SmsFallbackUrl', 'SmsStatusCallback' ].each do |key|
        it "includes #{key}" do
          expect(subject.send(:assemble_twilio_application_data)).to include(key)
        end
        it "embeds auth tokens in #{key}" do
          expect(subject.send(:assemble_twilio_application_data)[key]).to start_with(digest_auth)
        end
      end
      
      [ 'VoiceMethod', 'VoiceFallbackMethod', 'StatusCallbackMethod', 'SmsMethod', 'SmsFallbackMethod' ].each do |key|
        it "includes #{key}" do
          expect(subject.send(:assemble_twilio_application_data)).to include(key)
        end
        it "uses POST for #{key}" do
          expect(subject.send(:assemble_twilio_application_data)[key]).to eq('POST')
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
end
