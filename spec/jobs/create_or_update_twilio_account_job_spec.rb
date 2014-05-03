require 'spec_helper'

describe CreateOrUpdateTwilioAccountJob, :vcr, :skip do
  
  describe '#perform' do

    context 'when twilio gateway does not exist' do
      let(:organization) { create :organization, :with_sid_and_token }
      it 'does not raise error' do
        expect { subject.perform(organization.id) }.not_to raise_error
      end
      it 'adds #communication_gateway' do
        expect { subject.perform(organization.id) }.to change{organization.communication_gateway_for(:twilio)}.from(nil)
      end
      it 'adds #communication_gateway as TwilioCommunicationGateway' do
        subject.perform(organization.id)
        organization.communication_gateway_for(:twilio).should be_a TwilioCommunicationGateway
      end
      it 'sets #communication_gateway.twilio_account_sid' do
        subject.perform(organization.id)
        organization.communication_gateway_for(:twilio).twilio_account_sid.should_not be_nil
      end
      it 'sets #communication_gateway.twilio_auth_token' do
        subject.perform(organization.id)
        organization.communication_gateway_for(:twilio).twilio_auth_token.should_not be_nil
      end
      it 'sets #communication_gateway.remote_application' do
        subject.perform(organization.id)
        organization.communication_gateway_for(:twilio).remote_application.should_not be_nil
      end
    end

    context 'when twilio gateway already exists' do
      let(:organization) { create :organization, :with_sid_and_token, :with_mock_comms }
      it 'does not raise error' do
        expect { subject.perform(organization.id) }.not_to raise_error
      end
      it 'does not change #twilio_account_sid' do
        expect { subject.perform(organization.id) }.not_to change{organization.communication_gateway_for(:twilio).twilio_account_sid}
      end
      it 'does not change #twilio_auth_token' do
        expect { subject.perform(organization.id) }.not_to change{organization.communication_gateway_for(:twilio).twilio_auth_token}
      end
      it 'does not change #twilio_application_sid' do
        expect { subject.perform(organization.id) }.not_to change{organization.communication_gateway_for(:twilio).twilio_application_sid}
      end
    end
    
  end

end
