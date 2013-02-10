require 'spec_helper'

describe CreateTwilioAccountJob do
  before { VCR.insert_cassette 'accounts', record: :new_episodes }
  after { VCR.eject_cassette }
  
  describe '#perform' do
    subject { CreateTwilioAccountJob.new account.id }

    context 'when twilio account does not exist' do
      let(:account) { create :account }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'adds .twilio_account_sid' do
        expect { subject.perform }.to change{account.reload.twilio_account_sid}.from(nil)
      end
      it 'adds .twilio_auth_token' do
        expect { subject.perform }.to change{account.reload.twilio_auth_token}.from(nil)
      end
    end

    context 'when twilio account already exists' do
      let(:account) { create :account, :test_twilio }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'does not change account.twilio_account_sid' do
        expect { subject.perform }.to_not change{account.reload.twilio_account_sid}
      end
      it 'does not change account.twilio_auth_token' do
        expect { subject.perform }.to_not change{account.reload.twilio_auth_token}
      end
    end
    
  end

end
