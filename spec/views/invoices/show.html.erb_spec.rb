require 'spec_helper'

RSpec.describe "invoices/show", :type => :view do
  before(:each) do
    @invoice = assign(:invoice, Invoice.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
