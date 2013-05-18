require 'spec_helper'

describe 'routing to ledger_entries' do

  it 'allows indexing' do
    expect( :get => 'organizations/1/ledger_entries' ).to route_to( controller: 'ledger_entries', action: 'index', organization_id: '1' )
  end
  it 'allows showing' do
    expect( :get => 'organizations/1/ledger_entries/1' ).to route_to( controller: 'ledger_entries', action: 'show', id: '1', organization_id: '1' )
  end
#   it 'does not allow new' do
#     pending 'Needs analysis of how to block #show gloming on to "new".'
#     expect( :get => 'ledger_entries/new' ).not_to be_routable
#   end
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
