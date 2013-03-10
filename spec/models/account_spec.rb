require 'spec_helper'

describe Account do
  before { VCR.insert_cassette 'accounts', record: :new_episodes }
  after { VCR.eject_cassette }
  subject { create(:account) }

  describe '#primary_appliance' do
    
    context 'when primary is set' do
      let(:account)   { create :account }
      let(:appliance) { create :appliance, account: account, primary: true }
      let(:nonprimary_appliance) { account.appliances.where(primary: false).first }

      it 'has at least one primary appliance' do
        appliance.should_not be_nil
        account.appliances.size.should >= 2
        account.appliances.where( primary: true ).empty?.should be_false
      end

      it 'returns primary appliance' do
        appliance.should_not be_nil
        account.reload.primary_appliance.id.should eq(appliance.id)
        account.reload.primary_appliance.primary.should be_true
        account.reload.primary_appliance.id.should_not == nonprimary_appliance.id
      end
    end
    
    context 'when no default is set' do
      let(:account)   { create :account }
      let(:appliance) { create :appliance, account: account, primary: false }
      let(:nonprimary_appliance) { account.appliances.where(primary: false).first }
      
      it 'has no appliance set to primary' do
        appliance.should_not be_nil
        account.appliances.size.should >= 2
        account.appliances.where( primary: true ).empty?.should be_true
      end

      it 'returns first non-primary appliance' do
        account.primary_appliance.id.should_not eq(appliance.id)
        account.primary_appliance.id.should eq(nonprimary_appliance.id)
      end
    end

  end

end
