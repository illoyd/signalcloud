require 'spec_helper'

describe FreshBooksAccountingGateway, :vcr, :skio, :type => :model do
skip 'Block all FreshBooks connections for now' do
  let(:organization_without_contacts) { build :organization, contact_address: nil, billing_address: nil }

  context 'when new' do
    subject { build :fresh_books_accounting_gateway }

    describe '#freshbooks_client' do
      it 'throws error' do
        expect{ subject.freshbooks_client }.to raise_error(SignalCloud::MissingFreshBooksClientError)
      end
    end

    describe '#create_freshbooks_client!' do
      skip 'Need to work with FreshBooks for testing' do
        it 'creates a freshbooks client' do
          expect{ subject.create_freshbooks_client! }.not_to raise_error
        end
        it 'sets its remote sid' do
          expect{ subject.create_freshbooks_client! }.to change(subject, :remote_sid).from(nil)
        end
      end
      context 'when missing contact details' do
        subject { build :fresh_books_accounting_gateway, organization: organization_without_contacts }
        it 'requires contact details' do
          expect{ subject.create_freshbooks_client! }.to raise_error(SignalCloud::MissingContactDetailsError)
        end
      end
    end

    describe '#update_freshbooks_client!' do
      it 'throws an error' do
        expect{ subject.update_freshbooks_client! }.to raise_error
      end
    end

    describe '#record_credit' do
      let(:amount)      { BigDecimal.new '5.43' }
      it 'throws an error' do
        expect{ subject.record_credit(amount) }.to raise_error(SignalCloud::MissingFreshBooksClientError)
      end
    end

  end # context when new
  
  context 'when ready' do
    subject { build :fresh_books_accounting_gateway, :ready }

    describe '#freshbooks_client' do
      it 'returns instance of freshbooks account' do
        expect{ subject.freshbooks_client }.not_to raise_error
      end
    end

    describe '#create_freshbooks_client!' do
      it 'throws an error' do
        expect{ subject.create_freshbooks_client! }.to raise_error
      end
    end

    describe '#update_freshbooks_client!' do
      it 'updates the freshbooks client' do
        expect{ subject.update_freshbooks_client! }.not_to raise_error
      end
      it 'does not change the remote sid' do
        expect{ subject.update_freshbooks_client! }.not_to change(subject, :remote_sid)
      end
      context 'when missing contact details' do
        subject { build :fresh_books_accounting_gateway, :ready, organization: organization_without_contacts }
        it 'requires contact details' do
          expect{ subject.update_freshbooks_client! }.to raise_error(SignalCloud::MissingContactDetailsError)
        end
      end
    end

    describe '#assemble_freshbooks_payment_data' do
      let(:client)      { build :fresh_books_accounting_gateway, :ready }
      let(:amount)      { 5.43 }
      subject           { client.send(:assemble_freshbooks_payment_data, amount).fetch(:payment) }
  
      describe '[:client_id]' do
        subject { super()[:client_id] }
        it { is_expected.to eq(client.remote_sid) }
      end

      describe '[:amount]' do
        subject { super()[:amount] }
        it { is_expected.to eq(amount) }
      end

      describe '[:type]' do
        subject { super()[:type] }
        it { is_expected.to eq('Credit') }
      end
    end

    describe '#freshbooks_credits' do
      it 'is an indifferent hash' do
        expect(subject.freshbooks_credits).to be_a HashWithIndifferentAccess
      end
      it 'has only one item' do
        expect(subject.freshbooks_credits.size).to eq(1)
      end
      it 'includes USD' do
        expect(subject.freshbooks_credits).to include('USD')
      end
      it 'has a decimal value for USD' do
        expect(subject.freshbooks_credits[:USD]).to be_a BigDecimal
      end
    end
  
    describe '#record_credit' do
      let(:amount)      { BigDecimal.new '5.43' }

      it 'does not error' do
        expect { subject.record_credit(amount) }.not_to raise_error
      end
    end

  end # context when ready
  
  
  
  
  


#   describe '#find_freshbooks_client_by_email' do
# 
#     context 'when searching for an existing client' do
#       subject { create :organization, :test_freshbooks }
#       it 'finds the client' do
#         subject.find_freshbooks_client_by_email.should be_a Hash
#       end      
#       it 'includes specific keys' do
#         subject.find_freshbooks_client_by_email.should include( 'email', 'client_id' )
#       end      
#     end
#     
#     context 'when searching for a new client' do
#       let(:address) { create :address, email: 'new-freshbooks-client@signalcloudapp.com' }
#       subject { create :organization, :test_freshbooks, contact_address: address }
#       it 'nil is returned' do
#         subject.find_freshbooks_client_by_email.should be_nil
#       end
#     end
# 
#     context 'when missing its primary contact' do
#       subject { create :organization, :test_freshbooks, contact_address: nil, billing_address: nil }
#       it 'throws an error' do
#         expect{ subject.find_freshbooks_client_by_email }.to raise_error(SignalCloud::MissingContactDetailsError)
#       end
#     end
#     
#   end
end # Freshbooks pending block
end
