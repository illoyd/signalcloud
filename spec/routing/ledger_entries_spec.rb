require 'spec_helper'

describe 'routing to ledger_entries', :type => :routing do

  it 'allows indexing' do
    expect( :get => 'organizations/1/ledger_entries' ).not_to be_routable
  end
  it 'allows showing' do
    expect( :get => 'organizations/1/ledger_entries/1' ).to route_to( controller: 'ledger_entries', action: 'show', id: '1', organization_id: '1' )
  end
  it 'does not allow creating' do
    expect( :post => 'organizations/1/ledger_entries' ).not_to be_routable
  end
  it 'does not allow editing' do
    expect( :get => 'organizations/1/ledger_entries/1/edit' ).not_to be_routable
  end
  it 'does not allow updating' do
    expect( :put => 'organizations/1/ledger_entries/1' ).not_to be_routable
  end
  it 'does not allow deleting' do
    expect( :delete => 'organizations/1/ledger_entries/1' ).not_to be_routable
  end

end
