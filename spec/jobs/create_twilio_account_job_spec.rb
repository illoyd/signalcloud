require 'spec_helper'

describe CreateTwilioAccountJob, :vcr do
  
  describe '#perform' do
    subject { CreateTwilioAccountJob.new account.id }

    context 'when twilio account does not exist' do
      let(:account) { create :account, :with_sid_and_token }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'adds #twilio_account_sid' do
        expect { subject.perform }.to change{account.reload.twilio_account_sid}.from(nil)
      end
      it 'adds #twilio_auth_token' do
        expect { subject.perform }.to change{account.reload.twilio_auth_token}.from(nil)
      end
    end

    context 'when twilio account already exists' do
      let(:account) { create :account, :test_twilio, :with_sid_and_token }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'does not change #twilio_account_sid' do
        expect { subject.perform }.to_not change{account.reload.twilio_account_sid}
      end
      it 'does not change #twilio_auth_token' do
        expect { subject.perform }.to_not change{account.reload.twilio_auth_token}
      end
    end
    
    context 'when twilio application does not exist' do
      let(:account) { create :account, :master_twilio, :with_sid_and_token, twilio_application_sid: nil }
      it 'adds #twilio_application_sid' do
        expect { subject.perform }.to change{account.reload.twilio_application_sid}.from(nil)
      end
    end
    
    context 'when twilio application exists' do
      let(:account) { create :account, :master_twilio, :with_sid_and_token }
      it 'does not change #twilio_application_sid' do
        expect { subject.perform }.not_to change{account.reload.twilio_application_sid}
      end
    end
    
  end

end
