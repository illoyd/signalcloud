require 'spec_helper'

describe Organization, 'Freshbooks Integration', :vcr do
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

  describe '#create_freshbooks_client' do
  
    context 'when not configured' do
      subject { create :organization }
      it 'creates a freshbooks client' do
        expect{ subject.create_freshbooks_client }.to_not raise_error
      end
    end
  
    context 'when configured with users' do
      subject { create :organization, :test_freshbooks, :with_users }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client }.to raise_error(SignalCloud::FreshBooksClientAlreadyExistsError)
      end
    end
  
    context 'when configured without users' do
      subject { create :organization, :test_freshbooks, :with_users }
      it 'throws an error' do
        expect{ subject.create_freshbooks_client }.to raise_error(SignalCloud::FreshBooksError)
      end
    end
  
  end

end
