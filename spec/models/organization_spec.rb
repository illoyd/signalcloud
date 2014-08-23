require 'spec_helper'

describe Organization, :vcr, :type => :model do
  subject { create(:organization) }

  describe '#primary_stencil' do
    
    context 'when primary is set' do
      let(:organization)       { create :organization }
      let(:stencil)            { create :stencil, organization: organization, primary: true }
      let(:nonprimary_stencil) { organization.stencils.where(primary: false).first }

      it 'has at least one primary stencil' do
        expect(stencil).not_to be_nil
        expect(organization.stencils.size).to be >= 2
        expect(organization.stencils.where( primary: true ).empty?).to be_falsey
      end

      it 'returns primary stencil' do
        expect(stencil).not_to be_nil
        expect(organization.reload.default_stencil.id).to eq(stencil.id)
        expect(organization.reload.default_stencil.primary).to be_truthy
        expect(organization.reload.default_stencil.id).not_to eq(nonprimary_stencil.id)
      end
    end
    
    context 'when no default is set' do
      let(:organization)   { create :organization }
      let(:stencil) { create :stencil, organization: organization, primary: false }
      let(:nonprimary_stencil) { organization.stencils.where(primary: false).first }
      
      it 'has no stencil set to primary' do
        expect(stencil).not_to be_nil
        expect(organization.stencils.size).to be >= 2
        expect(organization.stencils.where( primary: true ).empty?).to be_truthy
      end

      it 'returns first non-primary stencil' do
        expect(organization.default_stencil.id).not_to eq(stencil.id)
        expect(organization.default_stencil.id).to eq(nonprimary_stencil.id)
      end
    end

  end
  
  describe '#communication_gateway_for' do
    subject { create :organization, :with_mock_comms, :with_twilio }
    
    it 'returns a mock gateway' do
      expect( subject.communication_gateway_for(:mock) ).to be_a(MockCommunicationGateway)
    end
    
    it 'returns a Twilio gateway' do
      expect( subject.communication_gateway_for(:twilio) ).to be_a(TwilioCommunicationGateway)
    end
    
    it 'raises error when requesting a Nexmo gateway' do
      expect{ subject.communication_gateway_for(:nexmo) }.to raise_error
    end
    
    it 'raises error when requesting any other gateway' do
      expect{ subject.communication_gateway_for(:ostriches) }.to raise_error
    end
  end
  
  describe '#ensure_account_balance' do
    subject { build :organization }
    it 'creates a new account balance object' do
      expect{ subject.save! }.to change(subject, :account_balance).from(nil)
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
        expect(subject.last_invoice_date).to be_within(1).of(date_to)
      end
    end

    it 'returns nil when no past invoices available' do
      expect(subject.last_invoice_date).to be_nil
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
  
#   describe '#status' do
#     
#     context 'when missing all account details' do
#       subject { build :organization }
#       its(:twilio_account_sid) { should be_nil }
#       its(:twilio_auth_token)  { should be_nil }
#       its(:braintree_id)       { should be_nil }
#       its(:freshbooks_id)      { should be_nil }
#       its(:status)             { should == Organization::TRIAL }
#     end
#     
#     context 'when only twilio details' do
#       subject { build :organization, :with_twilio }
#       its(:twilio_account_sid) { should_not be_nil }
#       its(:twilio_auth_token)  { should_not be_nil }
#       its(:braintree_id)       { should be_nil }
#       its(:freshbooks_id)      { should be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when only braintree account details' do
#       subject { build :organization, :with_braintree }
#       its(:twilio_account_sid) { should be_nil }
#       its(:twilio_auth_token)  { should be_nil }
#       its(:braintree_id)       { should_not be_nil }
#       its(:freshbooks_id)      { should be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when only freshbooks account details' do
#       subject { build :organization, :with_freshbooks }
#       its(:twilio_account_sid) { should be_nil }
#       its(:twilio_auth_token)  { should be_nil }
#       its(:braintree_id)       { should be_nil }
#       its(:freshbooks_id)      { should_not be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when missing twilio account details' do
#       subject { build :organization, :with_braintree, :with_freshbooks }
#       its(:twilio_account_sid) { should be_nil }
#       its(:twilio_auth_token)  { should be_nil }
#       its(:braintree_id)       { should_not be_nil }
#       its(:freshbooks_id)      { should_not be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when missing braintree account details' do
#       subject { build :organization, :with_twilio, :with_freshbooks }
#       its(:twilio_account_sid) { should_not be_nil }
#       its(:twilio_auth_token)  { should_not be_nil }
#       its(:braintree_id)       { should be_nil }
#       its(:freshbooks_id)      { should_not be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when missing freshbooks details' do
#       subject { build :organization, :with_twilio, :with_braintree }
#       its(:twilio_account_sid) { should_not be_nil }
#       its(:twilio_auth_token)  { should_not be_nil }
#       its(:braintree_id)       { should_not be_nil }
#       its(:freshbooks_id)      { should be_nil }
#       its(:status)             { should == Organization::PENDING }
#     end
#     
#     context 'when all account details are defined' do
#       subject { build :organization, :with_twilio, :with_freshbooks, :with_braintree }
#       its(:twilio_account_sid) { should_not be_nil }
#       its(:twilio_auth_token)  { should_not be_nil }
#       its(:braintree_id)       { should_not be_nil }
#       its(:freshbooks_id)      { should_not be_nil }
#       its(:status)             { should == Organization::READY }
#     end
#     
#   end
  
  describe '#conversation_count_by_status' do
    subject { build :organization }

    describe '#conversation_count_by_status' do
      subject { super().conversation_count_by_status }
      it { is_expected.to be_a Hash }
    end
  end
  
  describe '#billing_address' do
    let(:address) { white_house_address }
    subject       { create :organization, billing_address: address }
    [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
      it "retrieves #{attribute}" do
        organization_attribute = "billing_#{attribute}".to_sym
        expect(subject.billing_address.send(attribute)).to eq(subject.send(organization_attribute))
      end
    end
  end
  
  describe '#billing_address=' do
    context 'when setting a billing address' do
      let(:address) { white_house_address }
      subject       { create :organization, billing_address: nil }
      [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
        it "assigns #{attribute}" do
          expect{ subject.billing_address = address }.to change(subject, "billing_#{attribute}".to_sym).to(address.send(attribute))
        end
      end
    end
    
    context 'when setting nil' do
      let(:address) { Address.new }
      subject       { create :organization, billing_address: white_house_address }
      [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
        it "nullifies #{attribute}" do
          expect{ subject.billing_address = address }.to change(subject, "billing_#{attribute}".to_sym).to(nil)
        end
      end
    end
  end
  
  describe '#contact_address' do
    let(:address) { white_house_address }
    subject       { create :organization, contact_address: address }
    [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
      it "retrieves #{attribute}" do
        organization_attribute = "contact_#{attribute}".to_sym
        expect(subject.contact_address.send(attribute)).to eq(subject.send(organization_attribute))
      end
    end
  end
  
  describe '#contact_address=' do
    context 'when setting a contact address' do
      let(:address) { white_house_address }
      subject       { create :organization, contact_address: nil }
      [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
        it "assigns #{attribute}" do
          expect{ subject.contact_address = address }.to change(subject, "contact_#{attribute}".to_sym).to(address.send(attribute))
        end
      end
    end
    
    context 'when setting nil' do
      let(:address) { Address.new }
      subject { create :organization, contact_address: white_house_address }
      [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country ].each do |attribute|
        it "nullifies #{attribute}" do
          expect{ subject.contact_address = address }.to change(subject, "contact_#{attribute}".to_sym).to(nil)
        end
      end
    end
  end
  
  describe '#use_billing_as_contact_address' do
    let(:contact_address) { address }
    let(:billing_address) { white_house_address }
    subject { create :organization, contact_address: contact_address, billing_address: billing_address }
    context 'when true' do
      before { subject.use_billing_as_contact_address = true }
      it 'updates the contact address with the billing address' do
        expect{ subject.save }.to change{ subject.contact_address }.to(billing_address)
      end
      it 'leaves billing address' do
        expect{ subject.save }.not_to change{ subject.billing_address }
      end
    end
    context 'when false' do
      before { subject.use_billing_as_contact_address = false }
      it 'leaves contact address' do
        expect{ subject.save }.not_to change{ subject.contact_address }
      end
      it 'leaves billing address' do
        expect{ subject.save }.not_to change{ subject.billing_address }
      end
    end
  end
  
end
