require 'spec_helper'

describe Organization, :vcr do
  subject { create(:organization) }

  describe '#primary_stencil' do
    
    context 'when primary is set' do
      let(:organization)   { create :organization }
      let(:stencil) { create :stencil, organization: organization, primary: true }
      let(:nonprimary_stencil) { organization.stencils.where(primary: false).first }

      it 'has at least one primary stencil' do
        stencil.should_not be_nil
        organization.stencils.size.should >= 2
        organization.stencils.where( primary: true ).empty?.should be_false
      end

      it 'returns primary stencil' do
        stencil.should_not be_nil
        organization.reload.primary_stencil.id.should eq(stencil.id)
        organization.reload.primary_stencil.primary.should be_true
        organization.reload.primary_stencil.id.should_not == nonprimary_stencil.id
      end
    end
    
    context 'when no default is set' do
      let(:organization)   { create :organization }
      let(:stencil) { create :stencil, organization: organization, primary: false }
      let(:nonprimary_stencil) { organization.stencils.where(primary: false).first }
      
      it 'has no stencil set to primary' do
        stencil.should_not be_nil
        organization.stencils.size.should >= 2
        organization.stencils.where( primary: true ).empty?.should be_true
      end

      it 'returns first non-primary stencil' do
        organization.primary_stencil.id.should_not eq(stencil.id)
        organization.primary_stencil.id.should eq(nonprimary_stencil.id)
      end
    end

  end

  describe '#last_invoice_date' do
    #let(:organization) { create(:organization) }

    context 'has past invoices' do
      let(:date_from) { 1.month.ago.beginning_of_day }
      let(:date_to)   { 2.days.ago.end_of_day }
      let(:invoice)   { create :invoice, organization: subject, date_from: date_from, date_to: date_to }
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
      let(:ledger_entry) { create :ledger_entry, organization: subject, created_at: created_at }
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
  
  describe '#balance' do
    it 'updates balance automatically after change' do
      expect { subject.update_balance! 5.0 }.to change{ subject.balance }
    end
    it 'updates balance automatically after change' do
      expect { subject.update_balance! 0.0 }.not_to change{ subject.balance }
    end
  end
  
  describe '#update_balance!' do
    subject { create :organization }
    let(:multiplier) { 3 }

    context 'with BigDecimals' do
      let(:credit) { BigDecimal.new "1.2" }
      let(:debit)  { BigDecimal.new "-3.4" }
      let(:zero)   { BigDecimal.new "0" }

      it 'applies credit (+)' do
        expect { subject.update_balance! credit }.to change{ subject.balance }.by( credit )
      end
  
      it 'applies multiple credits (+)' do
        expect { multiplier.times { subject.update_balance! credit } }.to change{ subject.balance }.by( credit * multiplier )
      end
  
      it 'applies debit (-)' do
        expect { subject.update_balance! debit }.to change{ subject.balance }.by( debit )
      end
      
      it 'applies multiple debits (-)' do
        expect { multiplier.times { subject.update_balance! debit } }.to change{ subject.balance }.by( debit * multiplier )
      end
      
      it 'applies credit then debit' do
        expect { # credit -> debit
          subject.update_balance! credit
          subject.update_balance! debit
        }.to change{ subject.balance }.by( credit + debit )
      end
      
      it 'applies debit then credit' do
        expect { # debit -> credit
          subject.update_balance! debit
          subject.update_balance! credit
        }.to change{ subject.balance }.by( debit + credit )
      end
      
      it 'applies credit then debit then credit' do
        expect { # credit -> debit -> credit
          subject.update_balance! credit
          subject.update_balance! debit
          subject.update_balance! credit
        }.to change{ subject.balance }.by( credit + debit + credit )
      end
      
      it 'applies debit then credit then debit' do
        expect { # debit -> credit -> debit
          subject.update_balance! debit
          subject.update_balance! credit
          subject.update_balance! debit
        }.to change{ subject.balance }.by( debit + credit + debit )
      end
      
      it 'handles zero' do
        expect { subject.update_balance! zero }.not_to change{ subject.balance }
      end
    end
    
    context 'with integers' do
      let(:credit) { 1 }
      let(:debit)  { -2 }
      let(:zero)   { 0 }

      it 'applies credit (+)' do
        expect { subject.update_balance! credit }.to change{ subject.balance }.by( credit )
      end
  
      it 'applies multiple credits (+)' do
        expect { multiplier.times { subject.update_balance! credit } }.to change{ subject.balance }.by( credit * multiplier )
      end

      it 'handles zero' do
        expect { subject.update_balance! zero }.not_to change{ subject.balance }
      end

    end
    
    context 'with floats' do
      let(:credit) { 1.5 }
      let(:debit)  { -2.4 }
      let(:zero)   { 0.0 }

      it 'applies credit (+)' do
        expect { subject.update_balance! credit }.to change{ subject.balance }.by( credit )
      end
  
      it 'applies multiple credits (+)' do
        expect { multiplier.times { subject.update_balance! credit } }.to change{ subject.balance }.by( credit * multiplier )
      end

      it 'handles zero' do
        expect { subject.update_balance! zero }.not_to change{ subject.balance }
      end

    end
    
  end
  
end
