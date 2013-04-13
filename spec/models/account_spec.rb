require 'spec_helper'

describe Account, :vcr => { :cassette_name => "accounts" } do
  subject { create(:account) }

  describe '#primary_stencilb' do
    
    context 'when primary is set' do
      let(:account)   { create :account }
      let(:stencil) { create :stencil, account: account, primary: true }
      let(:nonprimary_stencilb) { account.stencils.where(primary: false).first }

      it 'has at least one primary stencil' do
        stencil.should_not be_nil
        account.stencils.size.should >= 2
        account.stencils.where( primary: true ).empty?.should be_false
      end

      it 'returns primary stencil' do
        stencil.should_not be_nil
        account.reload.primary_stencilb.id.should eq(stencil.id)
        account.reload.primary_stencilb.primary.should be_true
        account.reload.primary_stencilb.id.should_not == nonprimary_stencilb.id
      end
    end
    
    context 'when no default is set' do
      let(:account)   { create :account }
      let(:stencil) { create :stencil, account: account, primary: false }
      let(:nonprimary_stencilb) { account.stencils.where(primary: false).first }
      
      it 'has no stencil set to primary' do
        stencil.should_not be_nil
        account.stencils.size.should >= 2
        account.stencils.where( primary: true ).empty?.should be_true
      end

      it 'returns first non-primary stencil' do
        account.primary_stencilb.id.should_not eq(stencil.id)
        account.primary_stencilb.id.should eq(nonprimary_stencilb.id)
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
