require 'spec_helper'

describe Account, 'Freshbooks Integration' do
  before(:all) { VCR.insert_cassette 'accounts_freshbooks' }
  after(:all)  { VCR.eject_cassette }
  subject { create(:account) }

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

end
