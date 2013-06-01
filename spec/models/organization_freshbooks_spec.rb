require 'spec_helper'

describe Organization, 'FreshBooks Integration', :vcr do
  subject { create(:organization) }

  describe '#freshbooks_client' do

    context 'when not configured' do
      subject { create :organization }
      it 'throws error' do
        expect{ subject.freshbooks_client }.to raise_error(SignalCloud::MissingFreshBooksClientError)
      end
    end

    context 'when configured' do
      subject { create :organization, :test_freshbooks }
      it 'returns instance of twilio organization' do
        expect{ subject.freshbooks_client }.to_not raise_error
      end
    end

  end
  
  describe '#create_or_update_freshbooks_client!' do

    context 'when not already configured' do
      subject { create :organization }
      it 'creates a freshbooks client' do
        expect{ subject.create_or_update_freshbooks_client! }.to_not raise_error
      end
    end

    context 'when already configured' do
      subject { create :organization, :with_freshbooks }
      it 'updates the freshbooks client' do
        expect{ subject.create_or_update_freshbooks_client! }.to_not raise_error
      end
    end

    context 'when missing its primary contact' do
      subject { create :organization, contact_address: nil, billing_address: nil }
      it 'throws an error' do
        expect{ subject.create_or_update_freshbooks_client! }.to raise_error(SignalCloud::MissingContactDetailsError)
      end
    end

  end

  describe '#create_freshbooks_client!' do
  
    context 'when not configured' do
      subject { create :organization }
      it 'creates a freshbooks client' do
        expect{ subject.create_freshbooks_client! }.to_not raise_error
      end
    end
  
    context 'when already configured' do
      subject { create :organization, :test_freshbooks, :with_users }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client! }.to raise_error(SignalCloud::FreshBooksClientAlreadyExistsError)
      end
    end
    
    context 'when missing its primary contact' do
      subject { create :organization, contact_address: nil, billing_address: nil }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client! }.to raise_error(SignalCloud::MissingContactDetailsError)
      end
    end

  end

  describe '#update_freshbooks_client!' do
  
    context 'when not configured' do
      subject { create :organization }
      it 'throws an error' do
        expect{ subject.update_freshbooks_client! }.to raise_error(SignalCloud::MissingFreshBooksClientError)
      end
    end
  
    context 'when already configured' do
      subject { create :organization, :test_freshbooks, :with_users }
      it 'updates the freshbooks client' do
        expect{ subject.update_freshbooks_client! }.not_to raise_error
      end
    end
    
    context 'when missing its primary contact' do
      subject { create :organization, :test_freshbooks, contact_address: nil, billing_address: nil }
      it 'throws an error' do
        expect{ subject.update_freshbooks_client! }.to raise_error(SignalCloud::MissingContactDetailsError)
      end
    end
    
  end
  
  describe '#find_freshbooks_client_by_email' do

    context 'when searching for an existing client' do
      subject { create :organization, :test_freshbooks }
      it 'finds the client' do
        subject.find_freshbooks_client_by_email.should be_a Hash
      end      
      it 'includes specific keys' do
        subject.find_freshbooks_client_by_email.should include( 'email', 'client_id' )
      end      
    end
    
    context 'when searching for a new client' do
      let(:address) { create :address, email: 'new-freshbooks-client@signalcloudapp.com' }
      subject { create :organization, :test_freshbooks, contact_address: address }
      it 'nil is returned' do
        subject.find_freshbooks_client_by_email.should be_nil
      end
    end

    context 'when missing its primary contact' do
      subject { create :organization, :test_freshbooks, contact_address: nil, billing_address: nil }
      it 'throws an error' do
        expect{ subject.find_freshbooks_client_by_email }.to raise_error(SignalCloud::MissingContactDetailsError)
      end
    end
    
  end
  
  describe '#assemble_freshbooks_payment_data' do
    let(:organization)    { build(:organization, :test_freshbooks) }
    subject               { organization.assemble_freshbooks_payment_data(amount) }
    let(:amount)          { 5.43 }
    its([:client_id])     { should == organization.freshbooks_id }
    its([:amount])        { should == amount }
    its([:type])          { should == 'Credit' }
  end
  
  describe '#record_freshbooks_payment' do
    subject               { build(:organization, :test_freshbooks) }
    let(:amount)          { BigDecimal.new '5.43' }
    it 'does not error' do
      expect { subject.record_freshbooks_payment(amount) }.not_to raise_error
    end

    context 'when missing freshbooks client' do
      subject { build :organization }
      it 'throws an error' do
        expect{ subject.record_freshbooks_payment(amount) }.to raise_error(SignalCloud::MissingFreshBooksClientError)
      end
    end
  end
  
  describe '#freshbooks_credits' do
    subject { build(:organization, :test_freshbooks) }
    its(:freshbooks_credits) { should be_a HashWithIndifferentAccess }
    its(:freshbooks_credits) { should have(1).item }
    it 'includes USD' do
      subject.freshbooks_credits.should include('USD')
    end
    it 'has a decimal value for USD' do
      subject.freshbooks_credits[:USD].should be_a BigDecimal
    end
  end
  
end
