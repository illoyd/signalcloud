require 'spec_helper'

describe Account do
  before { VCR.insert_cassette 'accounts', record: :new_episodes }
  after { VCR.eject_cassette }
  #fixtures :accounts, :users
  subject { create(:account) }

  describe '#twilio_client' do

    context 'when not configured' do
      subject { create :account }
      it 'throws error when SID and Token are missing' do
        expect{ subject.twilio_client }.to raise_error(Ticketplease::MissingTwilioAccountError)
      end
      it 'throws error when SID is missing' do
        #subject.twilio_account_sid = nil
        subject.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
        expect{ subject.twilio_client }.to raise_error(Ticketplease::MissingTwilioAccountError)
      end
      it 'throws error when Token is missing' do
        subject.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
        #subject.twilio_auth_token = nil
        expect{ subject.twilio_client }.to raise_error(Ticketplease::MissingTwilioAccountError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_twilio }
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
        expect{ subject.twilio_account }.to raise_error(Ticketplease::MissingTwilioAccountError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_twilio }
      it 'returns instance of twilio account' do
        expect{ subject.twilio_account }.to_not raise_error
      end
    end

  end
  
  describe '#twilio_validator' do

    context 'when not configured' do
      subject { create :account }
      it 'throws error' do
        expect{ subject.twilio_validator }.to raise_error(Ticketplease::MissingTwilioAccountError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_twilio }
      it 'returns instance of twilio validator' do
        expect{ subject.twilio_validator }.to_not raise_error
      end
    end

  end
  
  describe '#freshbooks_client' do

    context 'when not configured' do
      subject { create :account }
      it 'throws error' do
        expect{ subject.freshbooks_client }.to raise_error(Ticketplease::MissingFreshBooksClientError)
      end
    end

    context 'when configured' do
      subject { create :account, :test_freshbooks }
      it 'returns instance of twilio account' do
        expect{ subject.freshbooks_client }.to_not raise_error
      end
    end

  end

  describe '#create_freshbooks_client' do
  
    context 'when not configured' do
      subject { create :account }
      it 'creates a freshbooks client' do
        expect{ subject.create_freshbooks_client }.to_not raise_error
      end
    end
  
    context 'when configured with users' do
      subject { create :account, :test_freshbooks, :with_users }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client }.to raise_error(Ticketplease::FreshBooksClientAlreadyExistsError)
      end
    end
  
    context 'when configured without users' do
      subject { create :account, :test_freshbooks, :with_users }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client }.to raise_error(Ticketplease::FreshBooksError)
      end
    end
  
  end
  
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
