require 'spec_helper'

describe 'routing to transactions' do

  it 'allows indexing' do
    expect( :get => 'transactions' ).to route_to( controller: 'transactions', action: 'index' )
  end
  it 'allows showing' do
    expect( :get => 'transactions/1' ).to route_to( controller: 'transactions', action: 'show', id: '1' )
  end
  it 'does not allow new' do
    pending 'Needs analysis of how to block #show gloming on to "new".'
    expect( :get => 'transactions/new' ).not_to be_routable
  end
  it 'does not allow creating' do
    expect( :post => 'transactions' ).not_to be_routable
  end
  it 'does not allow editing' do
    expect( :get => 'transactions/1/edit' ).not_to be_routable
  end
  it 'does not allow updating' do
    expect( :put => 'transactions/1' ).not_to be_routable
  end
  it 'does not allow deleting' do
    expect( :delete => 'transactions/1' ).not_to be_routable
  end

end
