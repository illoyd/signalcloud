require 'spec_helper'

describe Account do
  before(:all) { VCR.insert_cassette 'accounts' }
  after(:all)  { VCR.eject_cassette }
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

  describe '#last_invoice_date' do
    #let(:account) { create(:account) }

    context 'has past invoices' do
      let(:date_from) { 1.month.ago.beginning_of_day }
      let(:date_to)   { 2.days.ago.end_of_day }
      let(:invoice)   { create :invoice, account: subject, date_from: date_from, date_to: date_to }
      it 'does not raise an error' do
        invoice
        expect { subject.last_invoice_date }.not_to raise_error
      end
      it 'returns the date of the last invoice' do
        invoice
        subject.last_invoice_date.should be_within(1).of(date_to)
      end
    end

    context 'has ledger entries' do
      let(:created_at)   { 1.week.ago }
      let(:ledger_entry) { create :ledger_entry, account: subject, created_at: created_at }
      it 'does not raise an error' do
        ledger_entry
        expect { subject.last_invoice_date }.not_to raise_error
      end
      it 'returns the date of the first ledger entry' do
        ledger_entry
        subject.last_invoice_date.should eq( created_at )
      end
    end

    context 'has no ledger entries' do
      it 'raises an error' do
        expect { subject.last_invoice_date }.to raise_error
      end
    end
  end
  
end
