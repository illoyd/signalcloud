require 'spec_helper'

describe CreateOrUpdateTwilioAccountJob, :vcr do
  
  describe '#perform' do
    subject { CreateOrUpdateTwilioAccountJob.new organization.id }

    context 'when twilio gateway does not exist' do
      let(:organization) { create :organization, :with_sid_and_token }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'adds #communication_gateway' do
        expect { subject.perform }.to change{organization.communication_gateway(true)}.from(nil)
      end
      it 'adds #communication_gateway as TwilioCommunicationGateway' do
        subject.perform
        organization.communication_gateway(true).should be_a TwilioCommunicationGateway
      end
      it 'sets #communication_gateway.twilio_account_sid' do
        subject.perform
        organization.communication_gateway(true).twilio_account_sid.should_not be_nil
      end
      it 'sets #communication_gateway.twilio_auth_token' do
        subject.perform
        organization.communication_gateway(true).twilio_auth_token.should_not be_nil
      end
      it 'sets #communication_gateway.twilio_application_sid' do
        subject.perform
        organization.communication_gateway(true).twilio_application_sid.should_not be_nil
      end
    end

    context 'when twilio gateway already exists' do
      let(:organization) { create :organization, :with_sid_and_token, :master_twilio }
      it 'does not raise error' do
        expect { subject.perform }.to_not raise_error
      end
      it 'does not change #twilio_account_sid' do
        expect { subject.perform }.to_not change{organization.communication_gateway(true).twilio_account_sid}
      end
      it 'does not change #twilio_auth_token' do
        expect { subject.perform }.to_not change{organization.communication_gateway(true).twilio_auth_token}
      end
      it 'does not change #twilio_application_sid' do
        expect { subject.perform }.not_to change{organization.communication_gateway(true).twilio_application_sid}
      end
    end
    
  end

end
