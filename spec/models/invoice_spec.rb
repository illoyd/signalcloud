require 'spec_helper'

describe Invoice do
  before(:all) { VCR.insert_cassette 'invoices' }
  after(:all)  { VCR.eject_cassette }
  
  # let(:account) { create_freshbooks_account() }
  let(:account) { create :freshbooks_account }

  let(:november) { '2012-11-30'.to_datetime.end_of_month }
  let(:december) { '2012-12-31'.to_datetime.end_of_month }
  let(:january)  { '2013-01-30'.to_datetime.end_of_month }

  [ :account_id, :date_to ].each do |attribute|
    it { should validate_presence_of( attribute ) }
  end
  
  describe '#capture_uninvoiced_ledger_entries' do
    let(:november_invoice) { create(:invoice, account: account, date_to: november) }
    let(:december_invoice) { create(:invoice, account: account, date_to: december) }
    let(:january_invoice)  { create(:invoice, account: account, date_to: january) }
    
    it 'captures November 2012 (and earlier) entries' do
      expect{ november_invoice.capture_uninvoiced_ledger_entries }.to change{ november_invoice.ledger_entries(true).count }.from(0).to(44)
    end

    it 'captures December 2012 (and earlier) entries' do
      expect{ december_invoice.capture_uninvoiced_ledger_entries }.to change{ december_invoice.ledger_entries(true).count }.from(0).to(44+55)
    end

    it 'captures January 2013 (and earlier) entries' do
      expect{ january_invoice.capture_uninvoiced_ledger_entries }.to change{ january_invoice.ledger_entries(true).count }.from(0).to(44+55+33)
    end

    it 'captures December 2012 (only) entries' do
      november_invoice.capture_uninvoiced_ledger_entries
      expect{ december_invoice.capture_uninvoiced_ledger_entries }.to change{ december_invoice.ledger_entries(true).count }.from(0).to(55)
    end

    it 'captures January 2013 (only) entries' do
      november_invoice.capture_uninvoiced_ledger_entries
      december_invoice.capture_uninvoiced_ledger_entries
      expect{ january_invoice.capture_uninvoiced_ledger_entries }.to change{ january_invoice.ledger_entries(true).count }.from(0).to(33)
    end

  end
  
  describe '#create_invoice! and #send_invoice!' do
    context 'when invoice has not been created' do
      subject { build(:invoice, account: account) }
  
      it { should_not have_invoice }
  
      it 'creates invoice' do
        expect { subject.create_invoice! }.to_not raise_error()
      end
  
      it 'raises error if sent' do
        expect { subject.send_invoice! }.to raise_error(SignalCloud::ClientInvoiceNotCreatedError)
      end
    end
    
    context 'when invoice has been created' do
      subject { build(:invoice, freshbooks_invoice_id: 1, account: account) }
  
      it { should have_invoice }
  
      it 'raises error if created' do
        expect { subject.create_invoice! }.to raise_error(SignalCloud::ClientInvoiceAlreadyCreatedError)
      end
  
      it 'sends invoice' do
        expect { subject.send_invoice! }.to_not raise_error()
        subject.sent_at.should_not be_nil
      end
    end
  end
  
  describe '#construct_freshbooks_invoice_data' do
    subject { create(:invoice, account: account, date_from: november ) }
    before(:each) { subject.capture_uninvoiced_ledger_entries }
    
    it 'includes necessary data' do
      subject.construct_freshbooks_invoice_data.should include(:client_id, :lines)
    end
    
    it 'includes the freshbooks id' do
      subject.construct_freshbooks_invoice_data[:client_id].should == account.freshbooks_id
    end
    
    it 'includes ledger entry lines' do
      subject.construct_freshbooks_invoice_data[:lines].should_not be_empty
    end
  end
  
end
