require 'spec_helper'

describe Account, 'Twilio Integration', :vcr do
  subject { create(:account) }

  describe '#twilio_client' do

    context 'when not configured' do
      subject { create :account }
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

    context 'when configured' do
      subject { create :account, :test_twilio, :with_sid_and_token }
      it 'returns instance of twilio client' do
        expect { subject.twilio_client }.to_not raise_error
      end
      it 'returns instance of twilio client with expected SID' do
        subject.twilio_client.account_sid.should == ENV['TWILIO_TEST_ACCOUNT_SID']
      end
    end

  end
  
  describe '#twilio_account' do

    context 'when not configured' do
      subject { create :account }
      it 'throws error' do
        expect{ subject.twilio_account }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_twilio, :with_sid_and_token }
      it 'returns instance of twilio account' do
        expect{ subject.twilio_account }.to_not raise_error
      end
    end

  end
  
  describe '#twilio_validator' do

    context 'when not configured' do
      subject { create :account }
      it 'throws error' do
        expect{ subject.twilio_validator }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_twilio, :with_sid_and_token }
      it 'returns instance of twilio validator' do
        expect{ subject.twilio_validator }.to_not raise_error
      end
    end

  end
  
  describe '#create_twilio_account' do
    context 'when account already created' do
      subject { create :account, :test_twilio, :with_sid_and_token }
      it 'does not raise error' do
        expect{ subject.create_twilio_account }.to_not raise_error
      end
      it 'does not change #twilio_account_sid' do
        expect { subject.create_twilio_account }.to_not change(subject, :twilio_account_sid)
      end
      it 'does not change #twilio_auth_token' do
        expect { subject.create_twilio_account }.to_not change(subject, :twilio_auth_token)
      end
    end
  end
  
  describe '#create_twilio_account!' do

    context 'when account not already created' do
      subject { create :account, :with_sid_and_token }
      it 'does not raise error' do
        expect{ subject.create_twilio_account! }.to_not raise_error
      end
      it 'adds .twilio_account_sid' do
        expect { subject.create_twilio_account! }.to change(subject, :twilio_account_sid).from(nil)
      end
      it 'adds .twilio_auth_token' do
        expect { subject.create_twilio_account! }.to change(subject, :twilio_auth_token).from(nil)
      end
      it 'allows creating a twilio client' do
        expect{ subject.twilio_client }.to raise_error(SignalCloud::MissingTwilioAccountError)
        subject.create_twilio_account!
        expect{ subject.twilio_client }.to_not raise_error
      end
    end

    context 'when account already created' do
      subject { create :account, :test_twilio, :with_sid_and_token }
      it 'raises error' do
        expect{ subject.create_twilio_account! }.to raise_error(SignalCloud::TwilioAccountAlreadyExistsError)
      end
      it 'does not change .twilio_account_sid' do
        expect { subject.create_twilio_account! rescue nil }.to_not change(subject, :twilio_account_sid)
      end
      it 'does not change .twilio_auth_token' do
        expect { subject.create_twilio_account! rescue nil }.to_not change(subject, :twilio_auth_token)
      end
    end

  end
  
  describe '#create_or_update_twilio_application' do
  
    context 'when account is not configured' do
      let(:account)   { create :account, :with_sid_and_token }
      it 'raises error' do
        expect { account.create_or_update_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end
    
    context 'when application is not configured, creates' do
      let(:account)   { create :account, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
      it 'does not raise error' do
        expect { account.create_or_update_twilio_application }.to_not raise_error()
      end
      it 'returns a response' do
        account.create_or_update_twilio_application.should_not be_nil
      end
      it 'updates twilio application' do
        expect { account.create_or_update_twilio_application }.to change{ account.twilio_application_sid }.from(nil)
      end
    end
    
    context 'when application is configured, updates' do
      let(:account)   { create :account, :master_twilio, :with_sid_and_token }
      it 'does not raise error' do
        expect { account.create_or_update_twilio_application }.to_not raise_error()
      end
      it 'returns a response' do
        account.create_or_update_twilio_application.should_not be_nil
      end
      it 'does not change twilio application' do
        expect { account.create_or_update_twilio_application }.not_to change{ account.twilio_application_sid }
      end
    end
    
  end
  
  describe '#has_twilio_application?' do

    context 'when application is configured' do
      subject { create :account, :test_twilio }
      its(:'has_twilio_application?') { should be_true }
    end

    context 'when application is not configured' do
      subject { create :account }
      its(:'has_twilio_application?') { should be_false }
    end

  end
  
  describe '#create_twilio_application' do
    
    context 'when account is configured' do
      context 'and when application is configured' do
        subject { create :account, :master_twilio, :with_sid_and_token }
        it 'does not raise error' do
          expect { subject.create_twilio_application }.not_to raise_error
        end
        it 'does not change twilio_application_sid' do
          expect { subject.create_twilio_application }.not_to change(subject, :twilio_application_sid)
        end
        it 'returns nil (since nothing was created)' do
          subject.create_twilio_application.should be_nil
        end
      end

      context 'and when application is not configured' do
        subject { create :account, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
        it 'does not raise error' do
          expect { subject.create_twilio_application }.not_to raise_error
        end
        it 'returns a response object' do
          subject.create_twilio_application.should_not be_nil
        end
        it 'sets twilio_application_sid' do
          expect { subject.create_twilio_application }.to change(subject, :twilio_application_sid).from(nil)
        end
      end
    end
    
    context 'when account is not configured' do
      subject { create :account }
      it 'raises error' do
        expect{ subject.create_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

  end
  
  describe '#create_twilio_application!' do
    context 'when accout and application are configured' do
      subject { create :account, :master_twilio, :with_sid_and_token }
      it 'raises application-exists error' do
        expect { subject.create_twilio_application! }.to raise_error(SignalCloud::TwilioApplicationAlreadyExistsError)
      end
    end
  end
  
  describe '#update_twilio_application' do
    
    context 'when account is configured' do
      context 'and when application is configured' do
        subject { create :account, :master_twilio, :with_sid_and_token }
        it 'does not raise error' do
          expect { subject.update_twilio_application }.not_to raise_error
        end
        it 'does not change twilio_application_sid' do
          expect { subject.update_twilio_application }.not_to change(subject, :twilio_application_sid)
        end
        it 'returns response' do
          subject.update_twilio_application.should_not be_nil
        end
      end

      context 'and when application is not configured' do
        subject { create :account, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
        it 'does not raise error' do
          expect { subject.update_twilio_application }.not_to raise_error
        end
        it 'does not change twilio_application_sid' do
          expect { subject.update_twilio_application }.not_to change(subject, :twilio_application_sid).from(nil)
        end
        it 'returns nil (nothing updated)' do
          subject.update_twilio_application.should be_nil
        end
      end
    end
    
    context 'when account is not configured' do
      subject { create :account }
      it 'raises error' do
        expect{ subject.create_twilio_application }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

  end
  
  describe '#update_twilio_application!' do
    context 'when account is configured but application is not configured' do
      subject { create :account, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
      it 'raises application-missing error' do
        expect { subject.update_twilio_application! }.to raise_error(SignalCloud::MissingTwilioApplicationError)
      end
    end
  end
  
  describe '#twilio_*_url' do

    context 'when account is configured' do
      subject { create :account, :test_twilio }
      let(:digest_auth)             { "https://#{subject.account_sid}:#{subject.auth_token}" }
      its(:twilio_voice_url)        { should start_with(digest_auth) }
      its(:twilio_voice_status_url) { should start_with(digest_auth) }
      its(:twilio_sms_url)          { should start_with(digest_auth) }
      its(:twilio_sms_status_url)   { should start_with(digest_auth) }
    end

    context 'when account is not configured' do
      subject { create :account }
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

  end
  
  describe '#twilio_application_configuration' do

    context 'when account is configured' do
      subject { create :account, :test_twilio }
      let(:digest_auth) { "https://#{subject.account_sid}:#{subject.auth_token}" }
      its(:twilio_application_configuration) { should be_a Hash }

      [ 'VoiceUrl', 'VoiceFallbackUrl', 'StatusCallback', 'SmsUrl', 'SmsFallbackUrl', 'SmsStatusCallback' ].each do |key|
        its(:'twilio_application_configuration.keys') { should include(key) }
        it "embedds auth tokens in #{key}" do
          subject.twilio_application_configuration[key].should start_with(digest_auth)
        end
      end
      
      [ 'VoiceMethod', 'VoiceFallbackMethod', 'StatusCallbackMethod', 'SmsMethod', 'SmsFallbackMethod' ].each do |key|
        its(:'twilio_application_configuration.keys') { should include(key) }
        it "uses POST for #{key}" do
          subject.twilio_application_configuration[key].should == 'POST'
        end
      end

    end

    context 'when account is not configured' do
      subject { create :account }
      it 'raises error' do
        expect{ subject.twilio_application_configuration }.to raise_error(SignalCloud::MissingTwilioAccountError)
      end
    end

  end

end
