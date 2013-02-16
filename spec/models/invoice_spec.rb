require 'spec_helper'

describe Invoice do
  before { VCR.insert_cassette 'invoices', record: :new_episodes }
  after { VCR.eject_cassette }
  
  let(:account) { create_freshbooks_account() }

  [ :account_id, :date_from, :date_to ].each do |attribute|
    it { should validate_presence_of( attribute ) }
  end
  
  context 'when invoice has not been created' do
    subject { build(:invoice, account: account) }

    it { should_not have_invoice }

    it 'creates invoice' do
      expect { subject.create_invoice! }.to_not raise_error()
    end

    it 'raises error if sent' do
      expect { subject.send_invoice! }.to raise_error(Ticketplease::ClientInvoiceNotCreatedError)
    end
  end
  
  context 'when invoice has been created' do
    subject { build(:invoice, freshbooks_id: 1, account: account) }

    it { should have_invoice }

    it 'raises error if created' do
      expect { subject.create_invoice! }.to raise_error(Ticketplease::ClientInvoiceAlreadyCreatedError)
    end

    it 'sends invoice' do
      expect { subject.send_invoice! }.to_not raise_error()
      subject.sent_at.should_not be_nil
    end
  end
  
  context 'when invoice has not been sent' do
    pending
  end
  
  context 'when invoice has been sent' do
    pending
  end
  
end
