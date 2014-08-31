require 'spec_helper'

describe AccountPlan, :type => :model do

  describe '#phone_number_pricer' do
  
    context 'with a free pricer' do
      subject { build :account_plan }
      its(:phone_number_pricer) { is_expected.to be_a Pricers::FreePricer }
      its('phone_number_pricer.config') { is_expected.to eq(subject.phone_number_pricer_config) }
    end
  
    context 'with a simple pricer' do
      subject { build :payg_account_plan }
      its(:phone_number_pricer) { is_expected.to be_a Pricers::SimplePhoneNumberPricer }
      its('phone_number_pricer.config') { is_expected.to eq(subject.phone_number_pricer_config) }
    end

  end

  describe '#conversation_pricer' do

    context 'with a free pricer' do
      subject { build :account_plan }
      its(:conversation_pricer) { is_expected.to be_a Pricers::FreePricer }
      its('conversation_pricer.config') { is_expected.to eq(subject.conversation_pricer_config) }
    end
  
    context 'with a simple pricer' do
      subject { build :payg_account_plan }
      its(:conversation_pricer) { is_expected.to be_a Pricers::SimpleConversationPricer }
      its('conversation_pricer.config') { is_expected.to eq(subject.conversation_pricer_config) }
    end

  end

end
