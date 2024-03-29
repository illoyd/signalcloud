require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe InvoicesController, :type => :controller do

  let(:organization) { user.organizations.first }
  let(:invoice)      { create :invoice, organization: organization }

  context 'when billing liaison user' do
    let(:user) { create :billing_liaison_user }
    
    describe "GET index" do
      it "assigns all invoices as @invoices" do
        signin_user(user)
        get :index, {organization_id: organization.id}
        expect(assigns(:invoices)).to contain_exactly(invoice)
      end
    end
  
    describe "GET show" do
      it "assigns the requested invoice as @invoice" do
        signin_user(user)
        get :show, {organization_id: organization.id, id: invoice.id}
        expect(assigns(:invoice)).to eq(invoice)
      end
      it "assigns the ledger entries as @ledger_entries" do
        signin_user(user)
        get :show, {organization_id: organization.id, id: invoice.id}
        expect(assigns(:ledger_entries)).to eq(invoice.ledger_entries)
      end
    end
  
    describe "GET pending" do
      it "assigns @ledger_entries" do
        signin_user(user)
        get :show, {organization_id: organization.id, id: invoice.id}
        expect(assigns(:ledger_entries)).to eq(organization.ledger_entries.uninvoiced)
      end
    end
  end

  context 'when affiliated user' do
    let(:user) { create :affiliated_user }
    
    describe "GET index" do
      it "assigns all invoices as @invoices" do
        signin_user(user)
        get :index, {organization_id: organization.id}
        expect(assigns(:invoices)).to be_empty
      end
    end
  
    describe "GET show" do
      it "assigns the requested invoice as @invoice" do
        signin_user(user)
        get :show, {organization_id: organization.id, id: invoice.id}
        expect(assigns(:invoice)).to eq(invoice)
      end
    end
  end

end
