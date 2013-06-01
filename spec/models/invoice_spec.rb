require 'spec_helper'

describe Invoice, :vcr do
  
  # let(:organization) { create_freshbooks_account() }
  let(:organization) { create :freshbooks_account }

  let(:november) { '2012-11-30'.to_datetime.end_of_month }
  let(:december) { '2012-12-31'.to_datetime.end_of_month }
  let(:january)  { '2013-01-30'.to_datetime.end_of_month }
  
  let(:freshbooks_invoice_id) { 431652 }

  [ :organization, :date_to ].each do |attribute|
    it { should validate_presence_of( attribute ) }
  end

  describe '#capture_uninvoiced_ledger_entries' do
    let(:november_invoice) { create(:invoice, organization: organization, date_to: november) }
    let(:december_invoice) { create(:invoice, organization: organization, date_to: december) }
    let(:january_invoice)  { create(:invoice, organization: organization, date_to: january) }
    let(:november_count)   { 22 }
    let(:december_count)   { 33 }
    let(:january_count)    { 11 }
    
    it 'captures November 2012 (and earlier) entries' do
      expect{ november_invoice.capture_uninvoiced_ledger_entries }.to change{ november_invoice.ledger_entries(true).count }.from(0).to(november_count)
    end

    it 'captures December 2012 (and earlier) entries' do
      expect{ december_invoice.capture_uninvoiced_ledger_entries }.to change{ december_invoice.ledger_entries(true).count }.from(0).to(november_count+december_count)
    end

    it 'captures January 2013 (and earlier) entries' do
      expect{ january_invoice.capture_uninvoiced_ledger_entries }.to change{ january_invoice.ledger_entries(true).count }.from(0).to(november_count+december_count+january_count)
    end

    it 'captures December 2012 (only) entries' do
      november_invoice.capture_uninvoiced_ledger_entries
      expect{ december_invoice.capture_uninvoiced_ledger_entries }.to change{ december_invoice.ledger_entries(true).count }.from(0).to(december_count)
    end

    it 'captures January 2013 (only) entries' do
      november_invoice.capture_uninvoiced_ledger_entries
      december_invoice.capture_uninvoiced_ledger_entries
      expect{ january_invoice.capture_uninvoiced_ledger_entries }.to change{ january_invoice.ledger_entries(true).count }.from(0).to(january_count)
    end

  end
  
  describe '#prepare!' do
    subject { organization.create_next_invoice }

    it 'raises an invoice' do
      expect{ subject.prepare! }.not_to raise_error
    end
  end
  
  describe '#settle!' do
    subject { organization.create_next_invoice }

    it 'raises an invoice' do
      expect{ subject.settle! }.not_to raise_error
    end
  end
  
  describe '#freshbooks_invoice' do
    context 'when invoice has not been created' do
      subject { build(:invoice, organization: organization) }
      it 'raises error if requested' do
        expect { subject.freshbooks_invoice }.to raise_error(SignalCloud::ClientInvoiceNotCreatedError)
      end
    end
    
    context 'when invoice has been created' do
      subject { build(:invoice, freshbooks_invoice_id: freshbooks_invoice_id, organization: organization) }
      it 'returns a hash' do
        subject.freshbooks_invoice.should be_a Hash
      end
      it 'includes certain keys' do
        subject.freshbooks_invoice.should include( 'invoice_id', 'client_id', 'amount' )
      end
      it 'includes the invoice_id' do
        subject.freshbooks_invoice['invoice_id'].should == freshbooks_invoice_id.to_s
      end
    end
  end
  
  describe '#create_invoice! and #send_invoice!' do
    context 'when invoice has not been created' do
      subject { build(:invoice, organization: organization) }
  
      it { should_not have_invoice }
  
      it 'creates invoice' do
        expect { subject.create_invoice! }.to_not raise_error()
      end
  
      it 'raises error if sent' do
        expect { subject.send_invoice! }.to raise_error(SignalCloud::ClientInvoiceNotCreatedError)
      end
    end
    
    context 'when invoice has been created' do
      subject { build(:invoice, freshbooks_invoice_id: freshbooks_invoice_id, organization: organization) }
  
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
    subject { create(:invoice, organization: organization, date_from: november ) }
    before(:each) { subject.capture_uninvoiced_ledger_entries }
    
    it 'includes necessary data' do
      subject.construct_freshbooks_invoice_data.should include( 'client_id', 'lines' )
    end
    
    it 'includes the freshbooks id' do
      subject.construct_freshbooks_invoice_data[:client_id].should == organization.freshbooks_id
    end
    
    it 'includes ledger entry lines' do
      subject.construct_freshbooks_invoice_data[:lines].should have(2).lines
    end
  end

end
